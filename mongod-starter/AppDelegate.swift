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
    @IBOutlet weak var configFileCheckBox: NSButton!
    
    let statusItem = NSStatusBar.system().statusItem(withLength: -1)
    let defBinDir = UserDefaults.standard
    let defDataDir = UserDefaults.standard
    let configFileDir = UserDefaults.standard
    let useConfigFile = UserDefaults.standard
    var dataPath: String
    var binPath: String
    var configPath: String
    var task: Process = Process()
    var pipe: Pipe = Pipe()
    var file: FileHandle
    let mongodFile: String = "/mongod"
    
    override init() {
        self.file = self.pipe.fileHandleForReading
        
        if defDataDir.string(forKey: "defDataDir") != nil {
            self.dataPath = defDataDir.string(forKey: "defDataDir")!
        } else {
            self.dataPath = ""
        }
        
        if defBinDir.string(forKey: "defBinDir") != nil {
            self.binPath = defBinDir.string(forKey: "defBinDir")! + mongodFile
        } else {
            self.binPath = ""
        }
        
        if configFileDir.string(forKey: "configFileDir") != nil {
            self.configPath = configFileDir.string(forKey: "configFileDir")!
        } else {
            self.configPath = ""
        }
        
        super.init()
    }

    
    func startMongod() {
        self.task = Process()
        self.pipe = Pipe()
        self.file = self.pipe.fileHandleForReading
        
        if ((!FileManager.default.fileExists(atPath: self.binPath)) || (!FileManager.default.fileExists(atPath: self.dataPath))) {
            print("--> ERROR: Invalid path in UserDefaults")
            
            alert("Error: Invalid path", information: "MongoDB server and data storage locations are required. Go to Preferences.")
            
            return
        } else {
            let path = self.binPath
            self.task.launchPath = path
            
            if configFileCheckBox.state == NSOnState {
                if (FileManager.default.fileExists(atPath: self.configPath)) {
                    self.task.arguments = ["--dbpath", self.dataPath, "--nounixsocket", "--config", self.configPath]
                    
                    if let port = getPort() {
                        self.serverStatusMenuItem.title = "Running on Port \(port)"
                        
                    } else {
                        self.serverStatusMenuItem.title = "Running on Port 27017"
                    }

                }
            } else {
                self.task.arguments = ["--dbpath", self.dataPath, "--nounixsocket"]
                self.serverStatusMenuItem.title = "Running on Port 27017"
            }
            
            // Update status icon to active
            let icon = NSImage(named: "statusIconActive")
            icon?.isTemplate = false
            icon!.size = NSSize(width: 13.3, height: 18.3)
            statusItem.image = icon
            
            self.task.standardOutput = self.pipe
    
            self.serverStatusMenuItem.isHidden = false

            self.task.launch()
            print("-> MONGOD IS RUNNING...")
            
            self.startServerMenuItem.isHidden = true
            self.stopServerMenuItem.isHidden = false
        }
    }

    func stopMongod() {
        print("-> SHUTTING DOWN MONGOD")
        
        task.terminate()
        
        
        // Update status icon to inactive
        let appearance = UserDefaults.standard.string(forKey: "AppleInterfaceStyle") ?? "Light"
        var icon = NSImage(named: "statusIcon")
        if appearance == "Dark" {
            icon = NSImage(named: "statusIconDark")
        }
        icon?.isTemplate = false
        icon!.size = NSSize(width: 13.3, height: 18.3)
        statusItem.image = icon
        
        self.serverStatusMenuItem.isHidden = true
        self.startServerMenuItem.isHidden = false
        self.stopServerMenuItem.isHidden = true
        
        let data: Data = self.file.readDataToEndOfFile()
        
        self.file.closeFile()
    
        let output: String = NSString(data: data, encoding: String.Encoding.utf8.rawValue)! as String
        
        print(output)
    }
    
    // returns the path to be stored in the UserDefaults database
    func getDir(_ canChooseFiles: Bool, canChooseDirectories: Bool) -> String {
        let browser: NSOpenPanel = NSOpenPanel()
        
        browser.allowsMultipleSelection = false
        browser.canChooseFiles = canChooseFiles
        browser.canChooseDirectories = canChooseDirectories
        
        let i = browser.runModal()
        
        let url = browser.url
        let path: String
        
        if (url != nil) {
            path = url!.path
        } else {
            path = ""
        }
        
        if (i == NSModalResponseOK) {
            return path
        } else {
            return ""
        }
    }
    
    // scans the user's mongod configuration file for port changes
    func getPort() -> String? {
        let configPath = self.configPath
        
        do {
            let content = try String(contentsOfFile: configPath, encoding: String.Encoding.utf8)
            let contentArray = content.components(separatedBy: "\n")
            
            for (_, element) in contentArray.enumerated() {
                let lineContent = element.trimmingCharacters(in: CharacterSet.whitespaces)
                
                if ((lineContent.range(of: "port") != nil) || (lineContent.range(of: "Port") != nil)) {
                    if let port = lineContent.components(separatedBy: ":").last {
                        return port.trimmingCharacters(in: CharacterSet.whitespaces)
                    }
                }
            }
            
        } catch _ as NSError {
            return nil
        }
        return nil
    }
    
    // wraps NSAlert() methods
    func alert(_ message: String, information: String) {
        let alert = NSAlert()
        
        alert.messageText = message
        alert.informativeText = information
        
        alert.runModal()
    }

    
    /* ITEM ACTIONS */
    @IBAction func startServer(_ sender: NSMenuItem) {
        startMongod()
    }
   
    @IBAction func stopServer(_ sender: NSMenuItem) {
        stopMongod()
    }
    
    @IBAction func openPreferences(_ sender: NSMenuItem) {
        self.preferencesWindow!.orderFront(self)
        NSApplication.shared().activate(ignoringOtherApps: true)
    }
    
    @IBAction func browseBinDir(_ sender: NSButton) {
        binPathTextfield.stringValue = getDir(false, canChooseDirectories: true)
        defBinDir.set(binPathTextfield.stringValue, forKey: "defBinDir")
        self.binPath = defBinDir.string(forKey: "defBinDir")! + mongodFile
    }
    
    @IBAction func browseDataDir(_ sender: NSButton) {
        dataStoreTextfield.stringValue = getDir(false, canChooseDirectories: true)
        defDataDir.set(dataStoreTextfield.stringValue, forKey: "defDataDir")
        self.dataPath = defDataDir.string(forKey: "defDataDir")!
    }
    
    @IBAction func browseConfigDir(_ sender: NSButton) {
        configFileTextfield.stringValue = getDir(true, canChooseDirectories: false)
        configFileDir.set(configFileTextfield.stringValue, forKey: "configFileDir")
        self.configPath = configFileDir.string(forKey: "configFileDir")!
        
        configFileCheckBox.isEnabled = true
    }
    
    @IBAction func useConfigurationFile(_ sender: NSButton) {
        if configFileCheckBox.state == NSOnState {
            useConfigFile.set(true, forKey: "useConfigFile")
        } else if (configFileCheckBox.state == NSOffState) {
            useConfigFile.set(false, forKey: "useConfigFile")
        }
        useConfigFile.synchronize()
    }
    
    @IBAction func resetPreferences(_ sender: NSButton) {
        UserDefaults.standard.removeObject(forKey: "defDataDir")
        UserDefaults.standard.removeObject(forKey: "defBinDir")
        UserDefaults.standard.removeObject(forKey: "configFileDir")
        UserDefaults.standard.removeObject(forKey: "useConfigFile")
        dataStoreTextfield.stringValue = ""
        binPathTextfield.stringValue = ""
        configFileTextfield.stringValue = ""
        configFileCheckBox.isEnabled = false
        UserDefaults.standard.synchronize()
    }
    
    
    @IBAction func openAbout(_ sender: NSMenuItem) {
        NSApplication.shared().orderFrontStandardAboutPanel(sender)
        NSApplication.shared().activate(ignoringOtherApps: true)
    }
    
    @IBAction func openDoc(_ sender: NSMenuItem) {
        if let url: URL = URL(string: "https://github.com/gmontalvoriv/mongod-starter") {
            NSWorkspace.shared().open(url)
        }
    }
    
    @IBAction func openIssues(_ sender: NSMenuItem) {
        if let url: URL = URL(string: "https://github.com/gmontalvoriv/mongod-starter/issues") {
            NSWorkspace.shared().open(url)
        }
    }
    
    @IBAction func quit(_ sender: NSMenuItem) {
        NSApplication.shared().terminate(sender)
    }
    
    /* LAUNCH AND TERMINATION EVENTS */
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        self.preferencesWindow!.orderOut(self)
        
        if self.useConfigFile.bool(forKey: "useConfigFile") == true {
            configFileCheckBox.state = NSOnState
        } else {
            configFileCheckBox.state = NSOffState
        }
        
        if defDataDir.string(forKey: "defDataDir") != nil {
            let customDataDirectory = defDataDir.string(forKey: "defDataDir")!
            dataStoreTextfield.stringValue = customDataDirectory
        }
        
        if defBinDir.string(forKey: "defBinDir") != nil {
            let customBinDirectory = defBinDir.string(forKey: "defBinDir")!
            binPathTextfield.stringValue = customBinDirectory
        }
        
        if configFileDir.string(forKey: "configFileDir") != nil {
            let configFileDirectory = configFileDir.string(forKey: "configFileDir")!
            configFileTextfield.stringValue = configFileDirectory
            
            configFileCheckBox.isEnabled = true
        }
        
        let appearance = UserDefaults.standard.string(forKey: "AppleInterfaceStyle") ?? "Light"
        var icon = NSImage(named: "statusIcon")
        if appearance == "Dark" {
            icon = NSImage(named: "statusIconDark")
        }
        icon?.isTemplate = false
        icon!.size = NSSize(width: 13.3, height: 18.3)
        
        if let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String? {
            statusItem.toolTip = "mongod-starter \(version)"
        }
        
        statusItem.length = 27
        statusItem.image = icon
        statusItem.menu = statusMenu
        
        DistributedNotificationCenter.default.addObserver(self, selector: #selector(interfaceModeChanged(sender:)), name: NSNotification.Name(rawValue: "AppleInterfaceThemeChangedNotification"), object: nil)
    }
    
    
    func applicationWillTerminate(_ notification: Notification) {
        if (self.startServerMenuItem.isHidden == false) {
            return
        }
        
        stopMongod() // makes sure the server shuts down before quitting the application
    }
    
    func interfaceModeChanged(sender: NSNotification) {
        if(!self.startServerMenuItem.isHidden) {
            let appearance = UserDefaults.standard.string(forKey: "AppleInterfaceStyle") ?? "Light"
            var icon = NSImage(named: "statusIcon")
            if appearance == "Dark" {
                icon = NSImage(named: "statusIconDark")
            }
            icon?.isTemplate = false
            icon!.size = NSSize(width: 13.3, height: 18.3)
            statusItem.image = icon
        }
    }
}
