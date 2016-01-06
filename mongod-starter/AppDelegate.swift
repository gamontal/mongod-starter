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

    @IBOutlet weak var statusMenu: NSMenu!
    @IBOutlet weak var StartServItem: NSMenuItem!
    @IBOutlet weak var StopServItem: NSMenuItem!
    @IBOutlet weak var QuitItem: NSMenuItem!
    @IBOutlet weak var DocumentationItem: NSMenuItem!
    @IBOutlet weak var versionMenuItem: NSMenuItem!
    @IBOutlet weak var serverStatusMenuItem: NSMenuItem!
    @IBOutlet weak var PreferenceWindowItem: NSWindow!
    @IBOutlet weak var customBinTextfield: NSTextField!
    @IBOutlet weak var customDataTextfield: NSTextField!
    
    let customBinDir = NSUserDefaults.standardUserDefaults()
    let customDataDir = NSUserDefaults.standardUserDefaults()
    
    var paths = NSSearchPathForDirectoriesInDomains(
        NSSearchPathDirectory.DocumentDirectory,
        NSSearchPathDomainMask.UserDomainMask, true)
    
    var documentsDirectory: AnyObject
    var dataPath: String
    var binPath: String
    var appPath: String  // mongod-starter folder in Documents
    var logPath: String
    var task: NSTask = NSTask()
    var pipe: NSPipe = NSPipe()
    var file: NSFileHandle
    let mongodFile: String = "/mongod"
    
    let statusItem = NSStatusBar.systemStatusBar().statusItemWithLength(-1)
    
    override init() {
        self.file = self.pipe.fileHandleForReading
        self.documentsDirectory = self.paths[0]
        self.appPath = documentsDirectory.stringByAppendingPathComponent("mongod-starter")
        self.logPath = documentsDirectory.stringByAppendingPathComponent("mongod-starter/Logs")
        
        if customDataDir.stringForKey("defCustomDataDir") != nil {
            self.dataPath = customDataDir.stringForKey("defCustomDataDir")!
        } else {
            self.dataPath = ""
        }
        
        if customBinDir.stringForKey("defCustomBinDir") != nil {
            self.binPath = customBinDir.stringForKey("defCustomBinDir")! + mongodFile
        } else {
            
            self.binPath = ""
        }
        
        super.init()
    }
    
    
    func alert(message: String, information: String) {
        let alert = NSAlert()
        alert.messageText = message
        alert.informativeText = information

        alert.runModal()
    }
    
    
    // Start MongoDB server
    func startServer() {
        self.task = NSTask()
        self.pipe = NSPipe()
        self.file = self.pipe.fileHandleForReading
        
        if ((!NSFileManager.defaultManager().fileExistsAtPath(self.binPath)) || (!NSFileManager.defaultManager().fileExistsAtPath(self.dataPath))) {
            
            print("--> One of the directories was not found...")
            alert("An error has ocurred.", information: "Make sure both the binary and data storage paths exist before trying again.")
            
            return
        } else {
            
            let path = self.binPath
        
            self.task.launchPath = path
    
            self.task.arguments = ["--dbpath", self.dataPath, "--nounixsocket", "--logpath", "\(self.logPath)/mongo.log"]
            self.task.standardOutput = self.pipe
    
            print("-> mongod is running...")
            self.serverStatusMenuItem.hidden = false

            self.task.launch()
            
            self.StartServItem.hidden = true
            self.StopServItem.hidden = false
        }
    }
    
    // Stop MongoDB server
    func stopServer() {
        print("-> shutting down mongod")
        
        task.terminate()
        
        self.serverStatusMenuItem.hidden = true
        self.StartServItem.hidden = false
        self.StopServItem.hidden = true
        
        let data: NSData = self.file.readDataToEndOfFile()
        self.file.closeFile()
    
        let output: String = NSString(data: data, encoding: NSUTF8StringEncoding)! as String
        print(output)
    }
    
    func createAppDirectories() {
        
        if (!NSFileManager.defaultManager().fileExistsAtPath(self.appPath)) {
            do {
                try NSFileManager.defaultManager().createDirectoryAtPath(self.appPath, withIntermediateDirectories: false, attributes: nil)
            } catch {
                print("--> Failed creating the log directory...")
            }
        }
        
        if (!NSFileManager.defaultManager().fileExistsAtPath(self.logPath)) {
            do {
                try NSFileManager.defaultManager().createDirectoryAtPath(self.logPath, withIntermediateDirectories: false, attributes: nil)
            } catch {
                print("--> Failed creating the log directory...")
            }
        }
        print("mongod-starter path: \(self.appPath)")
        print("mongod-starter log path: \(self.logPath)")
    }
    
    // Item actions
    @IBAction func startMongoDBServer(sender: NSMenuItem) {
        startServer()
    }
    
    @IBAction func StopMongoDBServer(sender: NSMenuItem) {
        stopServer()
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
    
    
    @IBAction func openPreferences(sender: NSMenuItem) {
        self.PreferenceWindowItem!.orderFront(self)
        NSApplication.sharedApplication().activateIgnoringOtherApps(true)
    }
    
    
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
    
    
    @IBAction func browseBinDir(sender: NSButton) {
        customBinTextfield.stringValue = getDir(false, canChooseDirectories: true)
    }
    
    
    @IBAction func browseDataDir(sender: NSButton) {
        customDataTextfield.stringValue = getDir(false, canChooseDirectories: true)
    }
    
    
    @IBAction func SaveChanges(sender: NSButton) {
        customBinDir.setObject(customBinTextfield.stringValue, forKey: "defCustomBinDir")
        customDataDir.setObject(customDataTextfield.stringValue, forKey: "defCustomDataDir")
        
        self.binPath = customBinDir.stringForKey("defCustomBinDir")! + mongodFile
        self.dataPath = customDataDir.stringForKey("defCustomDataDir")!
        
        PreferenceWindowItem.close()
    }
    

    func applicationDidFinishLaunching(aNotification: NSNotification) {
        
        if customDataDir.stringForKey("defCustomDataDir") != nil {
            let customDataDirectory = customDataDir.stringForKey("defCustomDataDir")!
            customDataTextfield.stringValue = customDataDirectory
        }
        
        if customBinDir.stringForKey("defCustomBinDir") != nil {
            let customBinDirectory = customBinDir.stringForKey("defCustomBinDir")!
            customBinTextfield.stringValue = customBinDirectory
        }
        
        self.PreferenceWindowItem!.orderOut(self)
        if let version = NSBundle.mainBundle().objectForInfoDictionaryKey("CFBundleShortVersionString") as! String? {
            versionMenuItem.title = "mongod-starter v\(version)"
            versionMenuItem.hidden = false
        }
        
        createAppDirectories()
        
        let icon = NSImage(named: "statusIcon")
        icon!.size = NSSize(width: 20, height: 16)
        icon?.template = true

        statusItem.image = icon
        statusItem.menu = statusMenu
        
        // Sets quit action
        QuitItem.action = Selector("terminate:")
    }
    
    
    func applicationWillTerminate(notification: NSNotification) {
        if (self.StartServItem.hidden == false) {
            return
        }
        stopServer()
    }
}
