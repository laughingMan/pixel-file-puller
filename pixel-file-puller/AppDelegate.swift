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
    }
    
    private func showNotification(title: String, message: String) -> Void {
        let notification = NSUserNotification()
        notification.title = title
        notification.informativeText = message
        notification.soundName = NSUserNotificationDefaultSoundName
        
        let notificationCenter = NSUserNotificationCenter.default
        notificationCenter.deliver(notification)
    }
}

