//
//  ViewController.swift
//  safariSaver
//
//  Created by Andrew Godley on 18/12/2018.
//  Copyright © 2018 AG-Labs. All rights reserved.
//

import Cocoa
import WebKit
import Quartz
//import PDFKit

class ViewController: NSViewController {
    
    @IBOutlet weak var sourceSelect: NSPopUpButton!
    @IBOutlet weak var destinationSelect: NSTextField!
    @IBAction func destinationButton(_ sender: Any) {
        let dialog = NSOpenPanel()
        dialog.title                   = "Choose a Destination Folder"
        dialog.showsResizeIndicator    = false
        dialog.showsHiddenFiles        = false
        dialog.canChooseDirectories    = true
        dialog.canCreateDirectories    = false
        dialog.allowsMultipleSelection = false
        dialog.canChooseFiles = false
        
        if (dialog.runModal() == NSApplication.ModalResponse.OK) {
            let result = dialog.url // Pathname of the file
            if (result != nil) {
                let path = result?.path
                destinationSelect.stringValue = path!
            }
        } else {
            // User clicked on "Cancel"
            print("clicked cancel")
            return
        }
    }
    
    @IBAction func saveButton(_ sender: Any) {
        print("saving bookmarks from \(sourceSelect.selectedItem?.title) to \(destinationSelect.stringValue)")
    }
    
    @IBAction func quitButton(_ sender: Any) {
        NSApplication.shared.terminate(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let destinationDefault = NSSearchPathForDirectoriesInDomains(.desktopDirectory, .userDomainMask, true)[0]
        destinationSelect.stringValue = destinationDefault
        
        let homePath = FileManager.default.homeDirectoryForCurrentUser
        let fullPath = homePath.appendingPathComponent("Library/Safari/Bookmarks.plist")
        
        if let bookmarks = NSMutableDictionary(contentsOf: fullPath){
            let popUpContents = findBookmarkFolders(inBookmarks: bookmarks)
            sourceSelect.removeAllItems()
            //sourceSelect.addItem(withTitle: "All")
            //sourceSelect.addItems(withTitles: popUpContents)
            sourceSelect.addItems(withTitles: ["Practice","Level", "Location"])
            
        }
        
        let webView = WebView()
        //webView.mainFrame.loadHTMLString("www.google.com", baseURL: nil)
        let website = URL(string: "https://www.google.com")!
        let req = URLRequest(url: website)
        webView.preferences.shouldPrintBackgrounds = true
        
        let printInfo = NSPrintInfo.shared
        printInfo.paperSize = NSMakeSize(595.22, 841.85)
        printInfo.isHorizontallyCentered = true
        printInfo.isVerticallyCentered = true
        printInfo.orientation = .portrait
        printInfo.topMargin = 50
        printInfo.rightMargin = 0
        printInfo.bottomMargin = 50
        printInfo.leftMargin = 0
        printInfo.verticalPagination = .automatic
        printInfo.horizontalPagination = .fit
        
        
        
        //webView.mainFrame.frameView.allowsScrolling = false
        webView.mainFrame.load(req)
        let time = DispatchTime.now() + .seconds(1)
        DispatchQueue.main.asyncAfter(deadline: time, execute: {
            //let data = webView.dataWithPDF(inside: webView.mainFrame.frameView.documentView.frame)
            let data = webView.mainFrame.frameView.documentView.dataWithPDF(inside: webView.mainFrame.frameView.documentView.frame)
            let doc = PDFDocument.init(data: data)
            doc?.write(toFile: "/Users/andrewgodley/Desktop/test.pdf")
        })

    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        self.view.window?.title = "Bookamrks 2 PNG"
    }
    
    override var representedObject: Any? {
        didSet {
            // Update the view, if already loaded.
        }
    }
    
    func findBookmarkFolders(inBookmarks: NSMutableDictionary) -> [String] {
        var bookmarksOuterMenu = [NSMutableDictionary]()
        var rawBookmarks = [Dictionary<String, Any>]()
        
        let childrenBookmarks = inBookmarks["Children"] as! [NSMutableDictionary]
        var bookmarkFlag = false
        for item in childrenBookmarks{
            if (item["Title"] as? String == "BookmarksMenu") {
                bookmarksOuterMenu = item["Children"] as! [NSMutableDictionary]
                bookmarkFlag = true
                rawBookmarks = recursiveSearch(inDict: bookmarksOuterMenu, inArray: rawBookmarks, inDictLevel: 0)
            }
        }
        if !bookmarkFlag {
            print("No bookmarks found, have you changed the location of the Safari bookmarks file")
        }
        
        let preparedNames = prepareDictFolderNames(inBookmarks: rawBookmarks)
        return preparedNames
    }
    
    func recursiveSearch(inDict: [NSMutableDictionary], inArray: [Dictionary<String, Any>], inDictLevel: Int) -> ([Dictionary<String, Any>]) {
        var currDict = inArray
        for aChild in inDict{
            if aChild["Children"] != nil {
                let tempEntry = ["level": inDictLevel ,"Title": aChild["Title"]!]
                currDict.append(tempEntry)
                currDict = recursiveSearch(inDict: aChild["Children"] as! [NSMutableDictionary], inArray: currDict, inDictLevel: inDictLevel+1)
            }
        }
        return currDict
    }
    
    func prepareDictFolderNames(inBookmarks: [Dictionary<String, Any>]) -> ([String]) {
        var outArray = [String]()
        for item in inBookmarks{
            var prefix = ""
            let title = item["Title"] as! String
            let tabnumber = item["level"] as! Int
            for _ in 0 ..< tabnumber {
                prefix += "     "
            }
            outArray.append(prefix + title)
        }
        return outArray
    }
    
    
}

