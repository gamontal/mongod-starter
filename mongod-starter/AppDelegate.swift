//
//  AppDelegate.swift
//  mongod-starter
//
//  Created by Gabriel Montalvo on 1/4/16.
//  Copyright © 2016 Gabriel Montalvo. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    /* OUTLETS */
    @IBOutlet weak var statusMenu: NSMenu!
    @IBOutlet weak var serverStatusMenuItem: NSMenuItem!
    @IBOutlet weak var startServerMenuItem: NSMenuItem!
    @IBOutlet weak var stopServerMenuItem: NSMenuItem!
    @IBOutlet weak var preferencesWindow: NSWindow!
    @IBOutlet weak var binPathTextfield: NSTextField!
    @IBOutlet weak var dataStoreTextfield: NSTextField!
    @IBOutlet weak var configFileTextfield: NSTextField!
    @IBOutlet weak var showNotifCheckbox: NSButton!
    
    let statusItem = NSStatusBar.systemStatusBar().statusItemWithLength(-1)
    let defBinDir = NSUserDefaults.standardUserDefaults()
    let defDataDir = NSUserDefaults.standardUserDefaults()
    let configFileDir = NSUserDefaults.standardUserDefaults()
    let showNotifications = NSUserDefaults.standardUserDefaults()
    var dataPath: String
    var binPath: String
    var configPath: String
    var task: NSTask = NSTask()
    var pipe: NSPipe = NSPipe()
    var file: NSFileHandle
    let mongodFile: String = "/mongod"
    var showsDesktopNotifications: Bool = true
    
    override init() {
        self.file = self.pipe.fileHandleForReading
        
        if defDataDir.stringForKey("defDataDir") != nil {
            self.dataPath = defDataDir.stringForKey("defDataDir")!
        } else {
            self.dataPath = ""
        }
        
        if defBinDir.stringForKey("defBinDir") != nil {
            self.binPath = defBinDir.stringForKey("defBinDir")! + mongodFile
        } else {
            self.binPath = ""
        }
        
        if configFileDir.stringForKey("configFileDir") != nil {
            self.configPath = configFileDir.stringForKey("configFileDir")!
        } else {
            self.configPath = ""
        }
        
        super.init()
    }

    
    func startMongod() {
        self.task = NSTask()
        self.pipe = NSPipe()
        self.file = self.pipe.fileHandleForReading
        
        if ((!NSFileManager.defaultManager().fileExistsAtPath(self.binPath)) || (!NSFileManager.defaultManager().fileExistsAtPath(self.dataPath))) {
            print("--> ERROR: Invalid path in UserDefaults")
            
            alert("ERROR: Invalid path", information: "MongoDB server and data storage locations are required. Go to Preferences.")
            
            return
        } else {
            let path = self.binPath
            self.task.launchPath = path
            
            if (!NSFileManager.defaultManager().fileExistsAtPath(self.configPath)) {
                self.task.arguments = ["--dbpath", self.dataPath, "--nounixsocket"]
            } else {
                self.task.arguments = ["--dbpath", self.dataPath, "--nounixsocket", "--config", self.configPath]
            }
            
            self.task.standardOutput = self.pipe
    
            print("-> MONGOD IS RUNNING...")
            self.serverStatusMenuItem.hidden = false

            self.task.launch()
            
            if let port = getPort() {
                self.serverStatusMenuItem.title = "Running on Port \(port)"
                
                if showsDesktopNotifications {
                    showNotification("mongod-starter", text: "MongoDB server running on port \(port)", senderTitle: "Start MongoDB Server")
                }
                
            } else {
                self.serverStatusMenuItem.title = "Running on Port 27017"
                
                if showsDesktopNotifications {
                    showNotification("mongod-starter", text: "MongoDB server running on port 27017", senderTitle: "Start MongoDB Server")
                }
            }
            
            self.startServerMenuItem.hidden = true
            self.stopServerMenuItem.hidden = false
        }
    }

    func stopMongod() {
        print("-> SHUTTING DOWN MONGOD")
        
        task.terminate()
        
        if showsDesktopNotifications {
            showNotification("mongod-starter", text: "MongoDB server has been stopped", senderTitle: "Stop MongoDB Server")
        }
        
        self.serverStatusMenuItem.hidden = true
        self.startServerMenuItem.hidden = false
        self.stopServerMenuItem.hidden = true
        
        let data: NSData = self.file.readDataToEndOfFile()
        
        self.file.closeFile()
    
        let output: String = NSString(data: data, encoding: NSUTF8StringEncoding)! as String
        
        print(output)
    }
    
    // returns the path to be stored in the UserDefaults database
    func getDir(canChooseFiles: Bool, canChooseDirectories: Bool) -> String {
        let browser: NSOpenPanel = NSOpenPanel()
        
        browser.allowsMultipleSelection = false
        browser.canChooseFiles = canChooseFiles
        browser.canChooseDirectories = canChooseDirectories
        
        browser.runModal()
        
        let url = browser.URL
        let path: String
        
        if (url != nil) {
            path = url!.path!
        } else {
            path = ""
        }
        
        if (path != "") {
            return path
        } else {
            return ""
        }
    }
    
    // scans the user's mongod configuration file for port changes
    func getPort() -> String? {
        let configPath = self.configPath
        
        do {
            let content = try String(contentsOfFile: configPath, encoding: NSUTF8StringEncoding)
            let contentArray = content.componentsSeparatedByString("\n")
            
            for (_, element) in contentArray.enumerate() {
                let lineContent = element.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
                
                if ((lineContent.rangeOfString("port") != nil) || (lineContent.rangeOfString("Port") != nil)) {
                    if let port = lineContent.componentsSeparatedByString(":").last {
                        return port.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
                    }
                }
            }
            
        } catch _ as NSError {
            return nil
        }
        return nil
    }
    
    // wraps NSAlert() methods
    func alert(message: String, information: String) {
        let alert = NSAlert()
        
        alert.messageText = message
        alert.informativeText = information
        
        alert.runModal()
    }
    
    func showNotification(title: String, text: String, senderTitle: String) {
        let notification: NSUserNotification = NSUserNotification()
        notification.title = title
        notification.informativeText = text
        notification.hasActionButton = true
        notification.actionButtonTitle = senderTitle
        
        notification.deliveryDate = NSDate(timeIntervalSinceNow: 3)
        
        if let notificationcenter: NSUserNotificationCenter = NSUserNotificationCenter.defaultUserNotificationCenter() {
            notificationcenter.scheduleNotification(notification)
        }
    }

    
    /* ITEM ACTIONS */
    @IBAction func startServer(sender: NSMenuItem) {
        startMongod()
    }
   
    @IBAction func stopServer(sender: NSMenuItem) {
        stopMongod()
    }
    
    @IBAction func openPreferences(sender: NSMenuItem) {
        self.preferencesWindow!.orderFront(self)
        NSApplication.sharedApplication().activateIgnoringOtherApps(true)
    }
    
    @IBAction func browseBinDir(sender: NSButton) {
        binPathTextfield.stringValue = getDir(false, canChooseDirectories: true)
    }
    
    @IBAction func browseDataDir(sender: NSButton) {
        dataStoreTextfield.stringValue = getDir(false, canChooseDirectories: true)
    }
    
    @IBAction func browseConfigDir(sender: NSButton) {
        configFileTextfield.stringValue = getDir(true, canChooseDirectories: false)
    }
    
    @IBAction func savePrefChanges(sender: NSButton) {
        defBinDir.setObject(binPathTextfield.stringValue, forKey: "defBinDir")
        defDataDir.setObject(dataStoreTextfield.stringValue, forKey: "defDataDir")
        configFileDir.setObject(configFileTextfield.stringValue, forKey: "configFileDir")
        
        self.binPath = defBinDir.stringForKey("defBinDir")! + mongodFile
        self.dataPath = defDataDir.stringForKey("defDataDir")!
        self.configPath = configFileDir.stringForKey("configFileDir")!
        
        preferencesWindow.close()
    }
    
    @IBAction func openAbout(sender: NSMenuItem) {
        NSApplication.sharedApplication().orderFrontStandardAboutPanel(sender)
        NSApplication.sharedApplication().activateIgnoringOtherApps(true)
    }
    
    @IBAction func openDoc(sender: NSMenuItem) {
        if let url: NSURL = NSURL(string: "https://github.com/gmontalvoriv/mongod-starter") {
            NSWorkspace.sharedWorkspace().openURL(url)
        }
    }
    
    @IBAction func openIssues(sender: NSMenuItem) {
        if let url: NSURL = NSURL(string: "https://github.com/gmontalvoriv/mongod-starter/issues") {
            NSWorkspace.sharedWorkspace().openURL(url)
        }
    }
    
    @IBAction func quit(sender: NSMenuItem) {
        NSApplication.sharedApplication().terminate(sender)
    }
    
    @IBAction func showNotifications(sender: NSButton) {
        if showNotifCheckbox.state == NSOnState {
            showsDesktopNotifications = true
            showNotifications.setBool(true, forKey: "ShowNotifications")
        } else if showNotifCheckbox.state == NSOffState {
            showsDesktopNotifications = false
            showNotifications.setBool(false, forKey: "ShowNotifications")
        }
        showNotifications.synchronize()
    }
    
    /* LAUNCH AND TERMINATION EVENTS */
    func applicationDidFinishLaunching(aNotification: NSNotification) {
        self.preferencesWindow!.orderOut(self)
        
        if self.showNotifications.boolForKey("ShowNotifications") {
            showNotifCheckbox.state = NSOnState
        } else {
            showNotifCheckbox.state = NSOffState
        }
        
        if defDataDir.stringForKey("defDataDir") != nil {
            let customDataDirectory = defDataDir.stringForKey("defDataDir")!
            dataStoreTextfield.stringValue = customDataDirectory
        }
        
        if defBinDir.stringForKey("defBinDir") != nil {
            let customBinDirectory = defBinDir.stringForKey("defBinDir")!
            binPathTextfield.stringValue = customBinDirectory
        }
        
        if configFileDir.stringForKey("configFileDir") != nil {
            let configFileDirectory = configFileDir.stringForKey("configFileDir")!
            configFileTextfield.stringValue = configFileDirectory
        }
        
        let icon = NSImage(named: "statusIcon")
        icon?.template = true
        icon!.size = NSSize(width: 13.3, height: 18.3)
        
        if let version = NSBundle.mainBundle().objectForInfoDictionaryKey("CFBundleShortVersionString") as! String? {
            statusItem.toolTip = "mongod-starter \(version)"
        }
        
        statusItem.length = 27
        statusItem.image = icon
        statusItem.menu = statusMenu
    }
    
    
    func applicationWillTerminate(notification: NSNotification) {
        if (self.startServerMenuItem.hidden == false) {
            return
        }
        
        stopMongod() // makes sure the server shuts down before quitting the application
    }
}
