#!/usr/bin/env python3
# extract_strings.py
# استخراج سلاسل Base64 من ملف ثنائي
import re, sys
if len(sys.argv) < 2:
    print("Usage: python3 extract_strings.py <file>")
    sys.exit(1)
fn = sys.argv[1]
with open(fn,'rb') as f:
    data = f.read()
# نفكّ الترميز إلى latin1 حتى لا نفقد البايتات القابلة للطباعة
text = data.decode('latin1', errors='ignore')
# مرشح سريع لسلاسل base64 محتملة بطول 16+ (تعديل حسب الحاجة)
cands = sorted(set(re.findall(r'[A-Za-z0-9+/]{16,}={0,2}', text)))
for i,s in enumerate(cands,1):
    print(f"{i}: {s}")
print(f"Found {len(cands)} candidates.")
