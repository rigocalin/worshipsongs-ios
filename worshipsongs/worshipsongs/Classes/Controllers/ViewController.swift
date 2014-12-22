//
//  ViewController.swift
//  worshipsongs
//
//  Created by Seenivasan Sankaran on 12/18/14.
//  Copyright (c) 2014 Seenivasan Sankaran. All rights reserved.
//

import UIKit

let FONT_SIZE = 14.0
let CELL_CONTENT_WIDTH = 320.0
let CELL_CONTENT_MARGIN = 10.0

class ViewController: UITableViewController, UITableViewDataSource, NSXMLParserDelegate {
    
    var songLyrics = NSString()
    var parser: NSXMLParser = NSXMLParser()
    var eName: String = String()
    var lyricsContent = [String]()
    var postLink: String = String()
    var textView: UITextView!
    var songName: String = String()
    
    
    @IBOutlet var label: UILabel!
    
    override func viewDidLoad()  {
        super.viewDidLoad()
        self.navigationItem.title = songName;
        var lyrics: NSData = songLyrics.dataUsingEncoding(NSUTF8StringEncoding)!
        parser = NSXMLParser(data: lyrics)
        parser.delegate = self
        parser.parse()
        tableView.dataSource = self
        self.tableView.contentInset = UIEdgeInsetsMake(20, 0, 0, 0);
        // Reload the table
        self.tableView.reloadData()

    }
    
    override func tableView(tableView: UITableView,
        heightForFooterInSection section: Int) -> CGFloat
    {
        return 0.25;
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return self.lyricsContent.count
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
      return 1
        
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var dataCell : UITableViewCell? = tableView.dequeueReusableCellWithIdentifier("CELL_ID") as? UITableViewCell
        if(dataCell == nil)
        {
            dataCell = UITableViewCell(style: UITableViewCellStyle.Default, reuseIdentifier: "CELL_ID")
        }
        // get the items in this section
        var dataText = NSString()
        dataText = self.lyricsContent[indexPath.section]
        dataCell!.textLabel!.numberOfLines = 0
        dataCell!.textLabel!.lineBreakMode = NSLineBreakMode.ByWordWrapping;
        dataCell!.textLabel!.text = dataText
        return dataCell!
    }
    
    
    
    
    
    // MARK: - NSXMLParserDelegate methods
    
    func parser(parser: NSXMLParser!, didStartElement elementName: String!, namespaceURI: String!, qualifiedName qName: String!, attributes attributeDict: [NSObject : AnyObject]!) {
        eName = elementName
        if elementName == "verse" {
            let rel = attributeDict["type"] as? String
            println("Attributes: : \(rel)")
        }
    }
    
    func parser(parser: NSXMLParser!, foundCharacters string: String!) {
        let data = string.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
        if (!data.isEmpty) {
            if eName == "verse" {
                lyricsContent.append(data);
            }
        }
    }
    
    func parser(parser: NSXMLParser!, didEndElement elementName: String!, namespaceURI: String!, qualifiedName qName: String!) {
        if elementName == "lyrics" {
            let verseData: VerseModel = VerseModel()
            verseData.data = lyricsContent
            println("Verse Data : \(lyricsContent)")
        }
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
}
