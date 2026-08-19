const { app, BrowserWindow, ipcMain } = require('electron');
const path = require('path');

function createWindow() {
    const win = new BrowserWindow({
        width: 1200,
        height: 800,
        webPreferences: {
            nodeIntegration: false,
            contextIsolation: true,
            preload: path.join(__dirname, 'preload.js')
        },
        title: "My Crypto Wallet"
    });

    win.loadFile('index.html').catch(err => {
        console.error("خطأ في تحميل ملف index.html:", err);
    });
}

app.whenReady().then(createWindow);

app.on('window-all-closed', () => {
    if (process.platform !== 'darwin') app.quit();
});

// استقبال طلب الاتصال بـ Ledger من الواجهة الأمامية
ipcMain.handle('connect-ledger', async () => {
    try {
        const TransportNodeHid = require('@ledgerhq/hw-transport-node-hid').default;
        const transport = await TransportNodeHid.create();
        return { success: true, message: "تم الاتصال بـ Ledger بنجاح!" };
    } catch (error) {
        return { success: false, error: error.message };
    }
});
