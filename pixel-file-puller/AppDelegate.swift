//
//  AppDelegate.swift
//  pixel-file-puller
//
//  Created by isaac on 12/31/16.
//  Copyright © 2016 laughingMan. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, NSUserNotificationCenterDelegate {

    @IBOutlet weak var window: NSWindow!
    
    var statusBar: NSStatusItem!
    
    let NO_DEVICES_FOUND: String = "List of devices attached\n\n"
    let DOWNLOAD_FOLDER: String = "/Desktop/MOVIES"
    
    var DOWNLOAD_PATH: String = ""
    let ADB_PATH: String = "/usr/local/bin/adb"
    let MKDIR_PATH: String = "/bin/mkdir"
    let OPEN_PATH: String = "/usr/bin/open"
    let ECHO_PATH: String = "/bin/echo"

    func userNotificationCenter(_ center: NSUserNotificationCenter, shouldPresent notification: NSUserNotification) -> Bool {
        return true
    }
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        NSUserNotificationCenter.default.delegate = self
        
        //initialize menu bar icon
        let systemStatusBar = NSStatusBar.system()
        statusBar = systemStatusBar.statusItem(withLength: CGFloat(48))
        statusBar.button?.appearsDisabled = false
        statusBar.button?.image = NSImage.init(named: "menu-icon-image")
        
        statusBar.button?.action = #selector(launchTransfer)
        statusBar.button?.target = self
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    func launchTransfer(sender: AnyObject) {
        showNotification(title: "Transfers Started", message: "Please do not disconnect the phone from the computer.")
        
        statusBar.button?.appearsDisabled = true
        if (isDeviceConnected()) {
            let videoPathList = getVideoPaths()
            if (!videoPathList!.isEmpty) {
                createDirectoryToTransferTo()
                
                transferVideos(pathList: videoPathList!)
                
                print("transfer complete")
                showNotification(title: "Transfers Complete", message: "All movies have been transfered.")
                let _ = shell(launchPath: OPEN_PATH, arguments: [DOWNLOAD_FOLDER])
            } else {
                print("no files to transfer")
                showNotification(title: "Tranfer Error [No Videos Found]", message: "No video files found on the phone to transfer")
            }
        } else {
            print("no device found")
            showNotification(title: "No Android Device Found", message: "Check that your Android device is connected to the computer.")
        }
        
        statusBar.button?.appearsDisabled = false
    }
    
    private func isDeviceConnected() -> Bool {
        let checkForDeviceOutput = shell(launchPath: "/usr/local/bin/adb", arguments: ["devices"])
        return checkForDeviceOutput.0 != NO_DEVICES_FOUND
    }
    
    private func getVideoPaths() -> [String]? {
        let checkForDeviceOutput = shell(launchPath: ADB_PATH, arguments: ["shell", "ls", "/sdcard/DCIM/Camera/*.mp4"])
        
        if (checkForDeviceOutput.1 == 0) {
            let videoFilePaths = checkForDeviceOutput.0
            return videoFilePaths?.characters.split { $0 == "\n" || $0 == "\r\n" }.map(String.init)
        }
        
        return []
    }
    
    private func createDirectoryToTransferTo() {
        let _ = shell(launchPath: MKDIR_PATH, arguments: ["-p", getDownloadPath()])
        showNotification(title: "Transfers Folder created", message: "Folder created")
    }
    
    private func transferVideos(pathList: [String]) {
        // https://stackoverflow.com/questions/29548811/real-time-nstask-output-to-nstextview-with-swift
        showNotification(title: "Transfers Begining", message: "\(pathList.count) files to transfer")
        
        for path in pathList {
            let pathParts = path.characters.split { $0 == "/" }.map(String.init)
            let output = shell(launchPath: ADB_PATH, arguments: ["pull", path, getDownloadPath()])
            if (output.1 == 0) {
                print("download completed: " + path)
                showNotification(title: "Video Downloaded", message: pathParts.last!)
            } else {
                showNotification(title: "Transfer Error", message: "\(pathParts.last!) did not transfer.\nError Message: \(output.0)\nError Code: \(output.1)")
            }
        }
    }
    
    private func getDownloadPath() -> String {
        if (DOWNLOAD_PATH != "") {
            return DOWNLOAD_PATH
        }
        
        let userOutput = shell(launchPath: "/usr/bin/whoami", arguments: [])
        var homePath: String = userOutput.0!
        homePath = homePath.substring(to: homePath.index(before: homePath.endIndex))
        
        DOWNLOAD_PATH = "/Users/" + homePath + DOWNLOAD_FOLDER
        return DOWNLOAD_PATH
    }
    
    private func shell(launchPath: String, arguments: [String] = []) -> (String? , Int32) {
        let task = Process()
        task.launchPath = launchPath
        task.arguments = arguments
        
        // output sdout realtime
        let pipe = Pipe()
        let outHandle = pipe.fileHandleForReading
        outHandle.readabilityHandler = { pipe in
            if let line = String(data: pipe.availableData, encoding: String.Encoding.utf8) {
                // Update your view with the new text here
                print("New ouput: \(line)")
            } else {
                print("Error decoding data: \(pipe.availableData)")
            }
        }

        task.standardOutput = pipe
        task.standardError = pipe
        task.launch()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8)
        task.waitUntilExit()
        
        return (output, task.terminationStatus)
    }
    
    private func showNotification(title: String, message: String) -> Void {
        let notification = NSUserNotification()
        notification.title = title
        notification.informativeText = message
        notification.soundName = NSUserNotificationDefaultSoundName
        
        let notificationCenter = NSUserNotificationCenter.default
        notificationCenter.deliver(notification)
    }
  
    //  adb pull outputs: "[  1%] /sdcard/DCIM/Camera/VID_20161231_181434.mp4\n[  3%] /sdcard/DCIM/Camera/VID_20161231_181434.mp4\n" etc...
}
    
