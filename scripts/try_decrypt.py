#!/usr/bin/env python3
# try_decrypt.py
# يحاول فكّ سلاسل Base64 مشفّرة باستخدام المفتاح الذي تزوّده بصيغة hex أو base64.
# يجرب AES-GCM (IV 12 بايت, TAG 16 بايت) ثم AES-CBC (IV 16 بايت, PKCS#7)
import sys, base64, binascii
from Crypto.Cipher import AES

def unpad(b):
    pad = b[-1]
    if pad < 1 or pad > 16:
        raise ValueError("invalid padding")
    return b[:-pad]

def try_key_parse(kstr):
    # حاول hex أولاً ثم base64
    try:
        return binascii.unhexlify(kstr)
    except Exception:
        return base64.b64decode(kstr)

def try_aes_cbc(raw, key):
    if len(raw) <= 16:
        return None
    iv = raw[:16]
    ct = raw[16:]
    try:
        cipher = AES.new(key, AES.MODE_CBC, iv)
    except Exception:
        return None
    pt = cipher.decrypt(ct)
    try:
        return unpad(pt).decode('utf-8', errors='replace')
    except Exception:
        return None

def try_aes_gcm(raw, key):
    if len(raw) <= 12 + 16:
        return None
    iv = raw[:12]
    tag = raw[-16:]
    ct = raw[12:-16]
    try:
        cipher = AES.new(key, AES.MODE_GCM, nonce=iv)
        pt = cipher.decrypt_and_verify(ct, tag)
        return pt.decode('utf-8', errors='replace')
    except Exception:
        return None

if len(sys.argv) < 3:
    print("Usage: python3 try_decrypt.py BASE64_STRING KEY_HEX_OR_BASE64")
    sys.exit(1)

b64 = sys.argv[1]
key_in = sys.argv[2]
try:
    key = try_key_parse(key_in)
except Exception as e:
    print("Failed to parse key:", e); sys.exit(1)

if len(key) not in (16,24,32):
    print(f"Warning: parsed key length = {len(key)} bytes (AES keys must be 16/24/32). Continue anyway.")

try:
    raw = base64.b64decode(b64)
except Exception as e:
    print("Base64 decode failed:", e); sys.exit(1)

print("raw len:", len(raw))
res = try_aes_gcm(raw, key)
if res is not None:
    print("--- AES-GCM success ---")
    print(res)
else:
    print("AES-GCM failed or not applicable")

res = try_aes_cbc(raw, key)
if res is not None:
    print("--- AES-CBC success ---")
    print(res)
else:
    print("AES-CBC failed or not applicable")
