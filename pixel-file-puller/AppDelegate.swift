//
//  AppDelegate.swift
//  pixel-file-puller
//
//  Created by isaac on 12/31/16.
//  Copyright © 2016 laughingMan. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet weak var window: NSWindow!
    
    var statusBar: NSStatusItem!
    let NO_DEVICES_FOUND: String = "List of devices attached\n\n"


    func applicationDidFinishLaunching(_ aNotification: Notification) {
        
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
        
        if (isDeviceConnected()) {

        } else {
            print("no device found")
            showNotification(title: "No Android Device Found", message: "Check that your Android device is connected to the computer.")
        }
    }
    
    private func isDeviceConnected() -> Bool {
        let checkForDeviceOutput = shell(launchPath: "/usr/local/bin/adb", arguments: ["devices"])
        return checkForDeviceOutput.0 != NO_DEVICES_FOUND
    }
    
    private func showNotification(title: String, message: String) -> Void {
        let notification = NSUserNotification()
        notification.title = title
        notification.informativeText = message
        notification.soundName = NSUserNotificationDefaultSoundName
        
        let notificationCenter = NSUserNotificationCenter.default
        notificationCenter.deliver(notification)
    }
    
    private func shell(launchPath: String, arguments: [String] = []) -> (String? , Int32) {
        let task = Process()
        task.launchPath = launchPath
        task.arguments = arguments
        
        // output sdout realtime
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = pipe
        
        task.launch()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8)
        task.waitUntilExit()
        
        return (output, task.terminationStatus)
    }
}

