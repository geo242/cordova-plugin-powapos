//
//  PowaPOSPlugin.swift
//  BravaPOS
//
//  Created by Geoff Tripoli on 12/3/15.
//
//

import Foundation

@objc(PowaPOSPlugin) class PowaPOSPlugin: CDVPlugin, PowaTSeriesObserver, PowaScannerObserver, PowaRotationSensorObserver {
    var tseries: PowaTSeries!
    var powaPOS: PowaPOS!
    var scanner: PowaS10Scanner!
    
    var mainCallbackId: String?
    var scannerConnected = false
    var tseriesConnected = false
    
    override func pluginInitialize() {
        debugPrint("pluginInitialize")
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "accessoryDidConnect:", name: EAAccessoryDidConnectNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "accessoryDidDisconnect:", name: EAAccessoryDidDisconnectNotification, object: nil)
        EAAccessoryManager.sharedAccessoryManager().registerForLocalNotifications()
        self.powaPOS = PowaPOS()
        self.initDevices()
    }

    func initDevices() {
        debugPrint("initDevices")
        if (self.tseries == nil) {
            let connectedTSeries = PowaTSeries.connectedDevices()

            if (connectedTSeries.count > 0) {
                sendData("PowaTSeries_Info", data: "Found PowaTSeries")
                self.tseries = connectedTSeries[0] as! PowaTSeries
                self.tseries.addObserver(self)
                self.powaPOS.addPeripheral(self.tseries)
                tseriesConnected = true
            } else {
                sendData("PowaTSeries_Info", data: "Did not find PowaTSeries")
                tseriesConnected = false
            }
        }

        if (self.scanner == nil) {
            let connectedScanners = PowaS10Scanner.connectedDevices()

            if (connectedScanners.count > 0) {
                sendData("PowaTSeries_Info", data: "Found PowaS10Scanner")
                self.scanner = connectedScanners[0] as! PowaS10Scanner
                self.scanner.addObserver(self)
                self.powaPOS.addPeripheral(self.scanner)
                scannerConnected = true
            } else {
                sendData("PowaTSeries_Info", data: "Did not find PowaS10Scanner")
                scannerConnected = false
            }
        }
    }

    func accessoryDidConnect(notification: NSNotification) {
        sendData("PowaTSeries_Info", data: notification.description)
        self.initDevices()
    }

    func accessoryDidDisconnect(notification: NSNotification) {
        sendData("PowaTSeries_Info", data: notification.description)
    }

    override func dispose() {
        self.tseries.removeObserver(self)
        self.scanner.removeObserver(self)
    }

    //Commands
    func connect(command: CDVInvokedUrlCommand) {
        mainCallbackId = command.callbackId
        self.commandDelegate?.sendPluginResult(CDVPluginResult(status: CDVCommandStatus_OK, messageAsBool: true), callbackId: command.callbackId)
    }

    func scannerBeep(command: CDVInvokedUrlCommand) {
        if (self.scanner != nil) {
            var beepType = UInt(PowaS10ScannerBeepLong1BeepHigh)
            if (command.arguments.count > 0) {
                let firstArgument = command.arguments[0]
                if (firstArgument is NSNumber) {
                    beepType = PowaS10ScannerBeep(firstArgument as! NSNumber)
                }
            }
            self.scanner.beep(beepType)
            self.commandDelegate?.sendPluginResult(CDVPluginResult(status: CDVCommandStatus_OK, messageAsBool: true), callbackId: command.callbackId)
        } else {
            self.commandDelegate?.sendPluginResult(CDVPluginResult(status: CDVCommandStatus_OK, messageAsBool: false), callbackId: command.callbackId)
        }
    }

    func scannerAutoScanOnOff(command: CDVInvokedUrlCommand) {
        if (self.scanner != nil) {
            var autoScan = false;
            if (command.arguments.count > 0) {
                autoScan = (command.arguments[0] as! NSObject) == true
            }
            scanner.setScannerAutoScan(autoScan);
        } else {

        }
    }

    func openCashDrawer(command: CDVInvokedUrlCommand) {
        if (self.tseries != nil) {
            self.tseries.openCashDrawer()
            self.commandDelegate?.sendPluginResult(CDVPluginResult(status: CDVCommandStatus_OK, messageAsBool: true), callbackId: command.callbackId)
        } else {
            self.commandDelegate?.sendPluginResult(CDVPluginResult(status: CDVCommandStatus_OK, messageAsBool: false), callbackId: command.callbackId)
        }
    }

    func printReceipt(command: CDVInvokedUrlCommand) {
        debugPrint(command.arguments)
        if (self.tseries != nil && command.arguments.count > 0) {
            let receiptContent = command.argumentAtIndex(0) as! String

            let bold = "<bold>"
            let center = "<center>"
            let left = "<left>"
            let right = "<right>"
            let normal = "<normal>"
            let small = "<small>"
            let padCenter = "<padcenter>"
            let normalFont = UIFont.systemFontOfSize(26)
            let smallFont = UIFont.init(name: "Courier", size: 22)
            let boldFont = UIFont.boldSystemFontOfSize(26)
            let monoSpaceFont = UIFont.init(name: "Courier", size: 26)
            let monoSpaceBoldFont = UIFont.init(name: "Courier-Bold", size: 26)
            let footer = "\n\n\n"
            let totalCharacters = 36

            let receiptBuilder = PowaReceiptBuilder.init()
            var currentAlign = NSTextAlignment.Left
            var currentFont = normalFont

            let receiptContentLines = receiptContent.characters.split("\n").map(String.init)
            for line in receiptContentLines {
                var editedLine = line
                var isBold = false

                if (editedLine.containsString(bold)) {
                    editedLine = editedLine.stringByReplacingOccurrencesOfString(bold, withString: "")
                    currentFont = boldFont
                    isBold = true
                }

                if (editedLine.containsString(small)) {
                    editedLine = editedLine.stringByReplacingOccurrencesOfString(small, withString: "")
                    currentFont = smallFont!
                }

                if (editedLine.containsString(normal)) {
                    editedLine = editedLine.stringByReplacingOccurrencesOfString(normal, withString: "")
                    currentFont = normalFont
                }

                if (editedLine.containsString(center)) {
                    editedLine = editedLine.stringByReplacingOccurrencesOfString(center, withString: "")
                    currentAlign = NSTextAlignment.Center
                }

                if (editedLine.containsString(left)) {
                    editedLine = editedLine.stringByReplacingOccurrencesOfString(left, withString: "")
                    currentAlign = NSTextAlignment.Left
                }

                if (editedLine.containsString(right)) {
                    editedLine = editedLine.stringByReplacingOccurrencesOfString(right, withString: "")
                    currentAlign = NSTextAlignment.Right
                }

                if (editedLine.containsString(padCenter)) {
                    editedLine = editedLine.stringByReplacingOccurrencesOfString(padCenter, withString: "|")
                    let items = editedLine.characters.split("|").map(String.init)
                    let item1 = items.first
                    let item2 = items.last
                    let item1Length = item1?.characters.count
                    let item2Length = item2?.characters.count

                    if (item1Length! + item2Length! < totalCharacters) {
                        let paddingLength = totalCharacters - (item1Length! + item2Length!)
                        editedLine = (item1?.stringByPaddingToLength(((item1?.characters.count)! + paddingLength), withString: " ", startingAtIndex: 0))!
                        editedLine = editedLine.stringByAppendingString(item2!)
                    }
                    currentFont = (isBold ? monoSpaceBoldFont : monoSpaceFont)!
                }
                receiptBuilder.addText(editedLine, alignment: currentAlign, font: currentFont)
            }

            receiptBuilder.addText(footer, alignment: .Left, font: normalFont)

            self.tseries.printImage(receiptBuilder.receiptImage())
            self.commandDelegate?.sendPluginResult(CDVPluginResult(status: CDVCommandStatus_OK, messageAsBool: true), callbackId: command.callbackId)
        } else {
            self.commandDelegate?.sendPluginResult(CDVPluginResult(status: CDVCommandStatus_OK, messageAsBool: false), callbackId: command.callbackId)
        }
    }

    func getDeviceInfo(command: CDVInvokedUrlCommand) {

    }

    //Observer functions
    func tseries(tseries: PowaTSeries!, deviceConnectedAtPort port: UInt) {
        self.sendData("PowaTSeries_deviceConnectedAtPort", data: String(port))
    }
    func tseries(tseries: PowaTSeries!, deviceDisconnectedAtPort port: UInt) {
        self.sendData("PowaTSeries_deviceDisconnectedAtPort", data: String(port))
    }
    func tseries(tseries: PowaTSeries!, connectionStateChanged connectionState: UInt) {
        self.sendData("PowaTSeries_connectionStateChanged", data: String(connectionState))
    }
    func tseries(tseries: PowaTSeries!, bootcodeUpdateProgress progress: CGFloat) {
        self.sendData("PowaTSeries_bootcodeUpdateProgress", data: String(progress))
    }
    func tseries(tseries: PowaTSeries!, ftdiDeviceReceivedData data: NSData!, port: UInt) {
        let dataString = String.init(format: "{ dataReceived: '%@', port: '%@' }", data.base64EncodedStringWithOptions(NSDataBase64EncodingOptions.Encoding64CharacterLineLength), port)
        self.sendData("PowaTSeries_ftdiDeviceReceivedData", data: dataString)
    }
    func tseries(tseries: PowaTSeries!, hidDeviceConnectedAtPort port: UInt, deviceType type: PowaUSBHIDDeviceType) {
        let dataString = String.init(format: "{ port: '%@', deviceType: '%@' }", port, type == .Keyboard ? "keyboard" : "mouse")
        self.sendData("PowaTSeries_hidDeviceConnectedAtPort", data: dataString)
    }
    func tseries(tseries: PowaTSeries!, hidDeviceDisconnectedAtPort port: UInt, deviceType type: PowaUSBHIDDeviceType) {
        let dataString = String.init(format: "{ port: '%@', deviceType: '%@' }", port, type == .Keyboard ? "keyboard" : "mouse")
        self.sendData("PowaTSeries_hidDeviceDisconnectedAtPort", data: dataString)
    }
    func tseries(tseries: PowaTSeries!, hidDeviceReceivedData data: NSData!, port: UInt, deviceType type: PowaUSBHIDDeviceType) {
        let dataString = String.init(format: "{ dataReceived: '%@', port: '%@', deviceType: '%@' }", data.base64EncodedStringWithOptions(NSDataBase64EncodingOptions.Encoding64CharacterLineLength), port, type == .Keyboard ? "keyboard" : "mouse")
        self.sendData("PowaTSeries_hidDeviceConnectedAtPort", data: dataString)
    }
    func tseries(tseries: PowaTSeries!, format data: NSData!, port: UInt, deviceType type: PowaUSBHIDDeviceType) {
        let dataString = String.init(format: "{ dataReceived: '%@', port: '%@', deviceType: '%@' }", data.base64EncodedStringWithOptions(NSDataBase64EncodingOptions.Encoding64CharacterLineLength), port, type == .Keyboard ? "keyboard" : "mouse")
        self.sendData("PowaTSeries_hidDeviceReceivedData", data: dataString)
    }
    func tseries(tseries: PowaTSeries!, receivedData data: NSData!, port: UInt) {
        let dataString = String.init(format: "{ dataReceived: '%@', port: '%@' }", data.base64EncodedStringWithOptions(NSDataBase64EncodingOptions.Encoding64CharacterLineLength), port)
        self.sendData("PowaTSeries_receivedData", data: dataString)
    }
    func tseries(tseries: PowaTSeries!, updateProgress progress: CGFloat) {
        self.sendData("PowaTSeries_updateProgress", data:String(progress))
    }
    func tseriesCashDrawerAttached(tseries: PowaTSeries!) {
        self.sendData("PowaTSeries_tseriesCashDrawerAttached")
    }
    func tseriesCashDrawerDetached(tseries: PowaTSeries!) {
        self.sendData("PowaTSeries_tseriesCashDrawerDetached")
    }
    func tseriesDidFinishInitializing(tseries: PowaTSeries!) {
        self.sendData("PowaTSeries_tseriesDidFinishInitializing")
    }
    func tseriesDidFinishUpdating(tseries: PowaTSeries!) {
        self.sendData("PowaTSeries_tseriesDidFinishUpdating")
    }
    func tseriesDidFinishUpdatingBootcode(tseries: PowaTSeries!) {
        self.sendData("PowaTSeries_tseriesDidFinishUpdatingBootcode")
    }
    func tseriesDidStartUpdating(tseries: PowaTSeries!) {
        self.sendData("PowaTSeries_tseriesDidStartUpdating")
    }
    func tseriesDidStartUpdatingBootcode(tseries: PowaTSeries!) {
        self.sendData("PowaTSeries_tseriesDidStartUpdatingBootcode")
    }
    func tseriesFailedUpdatingBootcode(tseries: PowaTSeries!, error: NSError!) {
        self.sendData("PowaTSeries_tseriesFailedUpdatingBootcode", data: error.description)
    }
    func tseriesOutOfPaper(tseries: PowaTSeries!) {
        self.sendData("PowaTSeries_tseriesOutOfPaper")
    }
    func tseriesPrinterResult(result: PowaTSeriesPrinterResult) {
        var resultText = "Unknown"
        switch (result) {
        case .ErrorHardware:
            resultText = "ErrorHardware"
            break
        case .ErrorHeadUp:
            resultText = "ErrorHeadUp"
            break
        case .ErrorOutOfPaper:
            resultText = "ErrorOutOfPaper"
            break
        case .ErrorReceivingData:
            resultText = "ErrorReceivingData"
            break
        case .ErrorThermalMotor:
            resultText = "ErrorThermalMotor"
            break
        case .ErrorVoltage:
            resultText = "ErrorVoltage"
            break
        case .Ready:
            resultText = "Ready"
            break
        case .Successfull:
            resultText = "Successful"
            break
        }
        self.sendData("PowaTSeries_tseriesPrinterResult", data: resultText)
    }

    func scanner(scanner: PowaScanner!, connectionStateChanged connectionState: UInt) {
        sendData("PowaS10Scanner_connectionStateChanged", data: String(connectionState))
    }

    func scanner(scanner: PowaScanner!, scannedBarcode barcode: String!) {
        sendData("PowaS10Scanner_scannedBarcode", data: barcode)
    }

    func scanner(scanner: PowaScanner!, scannedBarcodeData data: NSData!) {
        sendData("PowaS10Scanner_scannedBarcodeData", data: data.base64EncodedStringWithOptions(NSDataBase64EncodingOptions.Encoding64CharacterLineLength))
    }

    func scannerDidFinishInitializing(scanner: PowaScanner!) {
        sendData("PowaScanner_scannerDidFinishInitializing")
    }

    func rotationSensor(rotationSensor: PowaRotationSensor!, rotated: Bool) {
        sendData("rotationSensor", data: String(rotated))
    }

    func peripheral(peripheral: PowaPeripheral, connectionStateChanged connectionState: PowaPeripheralConnectionState) {
        var state = ""
        if (Int(connectionState) == PowaPeripheralConnectionStateConnected) {
            state = "Connected"
        } else if (Int(connectionState) == PowaPeripheralConnectionStateConnecting) {
            state = "Connecting"
        } else {
            state = "Disconnected"
        }
        sendData("PowaPeripheral_connectionStateChanged", data: state)
    }

    func sendData(type: String, data: String! = nil) {
        var dataString = "null"
        if (data != nil) {
            if (data.containsString("{")) {
                dataString = data
            } else {
                dataString = "'" + data + "'"
            }
        }
        let js = String(format: "setTimeout(function () { window.plugins.powaPOS.handleDataReceived({ dataType: '%@', data: %@}); },0)", type, dataString)
        commandDelegate?.evalJs(js)
    }
}