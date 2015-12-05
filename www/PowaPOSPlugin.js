var exec = require("cordova/exec");
var pluginName = 'PowaPOSPlugin';

module.exports = {
    connect: function (success, error) {
        return execPromise(success, error, 'connect');
    },
    scannerBeep: function (beepType, success, error) {
        beepType = beepType || 0;
        return execPromise(success, error, 'scannerBeep', [beepType]);
    },
    scannerAutoScanOnOff: function (autoScan, success, error) {
        return execPromise(success, error, 'scannerAutoScanOnOff', [autoScan]);
    },
    openCashDrawer: function (success, error) {
        return execPromise(success, error, 'openCashDrawer')
    },
    printReceipt: function (receiptContent, success, error) {
        return execPromise(success, error, 'printReceipt', [receiptContent]);
    },
    handleDataReceived: function(data) {
        if (!!cordova && typeof cordova.fireWindowEvent === 'function') {
            cordova.fireWindowEvent('PowaPOS', data);
        }
    }
};


function execPromise(success, error, method, args) {
    return new Promise(function (resolve, reject) {
        exec(function (result) {
                resolve(result);
                if (typeof success === "function") {
                    success(result);
                }
            },
            function (reason) {
                reject(reason);
                if (typeof error === "function") {
                    error(reason);
                }
            },
            pluginName,
            method,
            args || []);
    });
}
