var exec = require("cordova/exec");

module.exports = {
    connect: function (success, error) {
        return execPromise(success, error, 'PowaPOSPlugin', 'connect', []);
    },
    scannerBeep: function (beepType, success, error) {
        beepType = beepType || 0;
        return execPromise(success, error, 'PowaPOSPlugin', 'scannerBeep', [beepType]);
    }
};

function execPromise(success, error, pluginName, method, args) {
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
            args);
    });
}