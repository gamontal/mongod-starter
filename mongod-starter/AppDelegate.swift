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
    @IBOutlet weak var serverStatusMenuItem: NSMenuItem!
    
    var paths = NSSearchPathForDirectoriesInDomains(
        NSSearchPathDirectory.DocumentDirectory,
        NSSearchPathDomainMask.UserDomainMask, true)
    
    var documentsDirectory: AnyObject
    var dataPath: String
    var binPath: String
    var task: NSTask = NSTask()
    var pipe: NSPipe = NSPipe()
    var file: NSFileHandle

    let statusItem = NSStatusBar.systemStatusBar().statusItemWithLength(-1)
    
    override init() {
        self.file = self.pipe.fileHandleForReading
        self.documentsDirectory = self.paths[0]
        self.dataPath = documentsDirectory.stringByAppendingPathComponent("MongoData")
        self.binPath = "\(NSHomeDirectory())/mongod-starter"
        
        super.init()
    }
    
    // Start MongoDB server
    func startServer() {
        self.task = NSTask()
        self.pipe = NSPipe()
        self.file = self.pipe.fileHandleForReading
    
        let path = "\(NSHomeDirectory())/mongod-starter/mongodb/bin/mongod"
        
        if (!NSFileManager.defaultManager().fileExistsAtPath(self.binPath)) {
            print("bin directory not found...")
            return
        } else {
        
            self.task.launchPath = path
    
            self.task.arguments = ["--dbpath", self.dataPath, "--nounixsocket"]
            self.task.standardOutput = self.pipe
    
            print("-> mongod is running...")
            self.serverStatusMenuItem.hidden = false

            self.task.launch()
        }
    }
    
    // Stop MongoDB server
    func stopServer() {
        print("-> shutting down mongod")
        
        task.terminate()
        
        let data: NSData = self.file.readDataToEndOfFile()
        self.file.closeFile()
    
        let output: String = NSString(data: data, encoding: NSUTF8StringEncoding)! as String
        print(output)
    }
    
    func createMongoBinDir() {
        if (!NSFileManager.defaultManager().fileExistsAtPath(self.binPath)) {
            do {
                try NSFileManager.defaultManager().createDirectoryAtPath(self.binPath,
                    withIntermediateDirectories: false, attributes: nil)
            } catch {
                print("An error has occurred. Bin directory was not created.")
            }
        }
        print("Mongo binaries directory: \(self.binPath)")
    }
    
    func createDataDir() {
        if (!NSFileManager.defaultManager().fileExistsAtPath(self.dataPath)) {
            do {
                try NSFileManager.defaultManager().createDirectoryAtPath(self.dataPath,
                    withIntermediateDirectories: false, attributes: nil)
            } catch {
                print("An error has occurred. Data directory was not created.")
            }
        }
        print("Mongo data directory: \(self.dataPath)")
    }
    
    // Item actions
    @IBAction func startMongoDBServer(sender: NSMenuItem) {
        self.StartServItem.hidden = true
        self.StopServItem.hidden = false
        
        startServer()
    }
    
    @IBAction func StopMongoDBServer(sender: NSMenuItem) {
        self.serverStatusMenuItem.hidden = true
        self.StartServItem.hidden = false
        self.StopServItem.hidden = true
        
        stopServer()
    }
    
    @IBAction func openDoc(sender: NSMenuItem) {
        if let url: NSURL = NSURL(string: "https://github.com/gmontalvoriv/mongod-starter") {
            NSWorkspace.sharedWorkspace().openURL(url)
        }
    }
    
    // app launch and termination events
    func applicationDidFinishLaunching(aNotification: NSNotification) {
        createDataDir() // creates mongodb data source location if it doesn't exist
        createMongoBinDir()
        
        let icon = NSImage(named: "statusIcon")
        icon!.size = NSSize(width: 20, height: 16)
        icon?.template = true

        statusItem.image = icon
        statusItem.menu = statusMenu
        
        // Sets quit action
        QuitItem.action = Selector("terminate:")
    }
    
    func applicationWillTerminate(notification: NSNotification) {
        if (self.StartServItem.hidden == false) { // If the receiver has not been launched yet, the terminate method raises an NSInvalidArgumentException.
            return                                // However after going throw the documentation I did not found a way to catch this exception during the execution
        }                                         // of the stopServer() function. So the item.hidden validation method will have to suffice.
        stopServer()
    }
}
