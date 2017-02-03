//
//  SongWithVideoViewController.swift
//  worshipsongs
//
//  Created by Vignesh Palanisamy on 23/12/2016.
//  Copyright © 2016 Vignesh Palanisamy. All rights reserved.
//

import UIKit
import YouTubePlayer
import KCFloatingActionButton

class SongWithVideoViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, XMLParserDelegate {
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var player: YouTubePlayerView!
    @IBOutlet weak var actionButton: UIButton!
    @IBOutlet weak var buttonTop: NSLayoutConstraint!
    @IBOutlet weak var playerHeight: NSLayoutConstraint!
    var secondWindow: UIWindow?
    var secondScreenView: UIView?
    var externalLabel = UILabel()
    var floatingbutton = KCFloatingActionButton()
    var hadYoutubeLink = false

    let customTextSettingService:CustomTextSettingService = CustomTextSettingService()
    let presentationData = PresentationData()
    var songName: String = ""
    var authorName = ""
    var songLyrics: NSString = NSString()
    var verseOrder: NSArray = NSArray()
    var element:String!
    var attribues : NSDictionary = NSDictionary()
    var listDataDictionary : NSMutableDictionary = NSMutableDictionary()
    var parsedVerseOrderList: NSMutableArray = NSMutableArray()
    var verseOrderList: NSMutableArray = NSMutableArray()
    var text: String!
    var presentationIndex = 0
    var comment: String = ""
    fileprivate let preferences = UserDefaults.standard
    var play = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        addFloatButton()
        addShareBarButton()
        if !comment.isEmpty && parseSongUrl() != "" {
            loadYoutube(url: parseSongUrl())
            floatingbutton.isHidden = false
            actionButton.isHidden = true
            hadYoutubeLink = true
        } else {
            floatingbutton.isHidden = true
            actionButton.isHidden = false
            hadYoutubeLink = false
        }
        player.isHidden = true
        playerHeight.constant = 0
        self.navigationItem.title = songName
        let lyrics: Data = songLyrics.data(using: String.Encoding.utf8.rawValue)!
        let parser = XMLParser(data: lyrics)
        parser.delegate = self
        parser.parse()
        if(verseOrderList.count < 1){
            print("parsedVerseOrderList:\(parsedVerseOrderList)")
            verseOrderList = parsedVerseOrderList
        }
        self.tableView.estimatedRowHeight = 88.0
        self.tableView.rowHeight = UITableViewAutomaticDimension
        let screenSize = UIScreen.main.bounds
        let screenHeight = screenSize.height
        buttonTop.constant = screenHeight - 125
        actionButton.layer.cornerRadius = actionButton.layer.frame.height / 2
        actionButton.clipsToBounds = true
    }
    
    func addFloatButton() {
        let playItem = getKCFloatingActionButtonItem(title: "playSong".localized, icon: UIImage(named: "play")!)
        playItem.handler = { item in
            self.floatingbutton.close()
            self.setAction()
        }
        floatingbutton.addItem(item: playItem)
        let presentationItem = getKCFloatingActionButtonItem(title: "presentSong".localized, icon: UIImage(named: "presentation")!)
        presentationItem.handler = { item in
            self.floatingbutton.close()
            self.presentation()
        }
        floatingbutton.addItem(item: presentationItem)
        floatingbutton.sticky = true
        floatingbutton.buttonColor = UIColor.red
        floatingbutton.plusColor = UIColor.white
        floatingbutton.size = 50
        self.view.addSubview(floatingbutton)
    }
    
    func getKCFloatingActionButtonItem(title: String, icon: UIImage) -> KCFloatingActionButtonItem {
        let item = KCFloatingActionButtonItem()
        item.size = 43
        item.buttonColor = UIColor.cruncherBlue()
        item.title = title
        item.titleColor = UIColor.black
        item.titleLabel.backgroundColor = UIColor.white
        item.titleLabel.layer.cornerRadius = 6
        item.titleLabel.clipsToBounds = true
        item.titleLabel.font = UIFont.systemFont(ofSize: 14)
        item.titleLabel.frame.size.width = item.titleLabel.frame.size.width + 2
        item.titleLabel.frame.size.height = item.titleLabel.frame.size.height + 2
        item.titleLabel.textAlignment = NSTextAlignment.center
        item.icon = icon
        return item
    }
    
    func getTableFooterView() -> UIView {
        let footerview = UIView(frame: CGRect(x: 0, y: 0, width: self.tableView.frame.width, height: 0))
        footerview.backgroundColor = UIColor.groupTableViewBackground
        return footerview
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.tableView.reloadData()
        presentationData.setupScreen()
        self.onChangeOrientation(orientation: UIDevice.current.orientation)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Table view data source
    
    func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        print("row\(self.verseOrderList.count)")
        return self.verseOrderList.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let key: String = (verseOrderList[(indexPath as NSIndexPath).section] as! String).lowercased()
        print("key\(key)")
        let dataText: NSString? = listDataDictionary[key] as? NSString
        cell.textLabel!.numberOfLines = 0
        let fontSize = self.preferences.integer(forKey: "fontSize")
        cell.textLabel?.font = UIFont.systemFont(ofSize: CGFloat(fontSize))
        cell.textLabel!.lineBreakMode = NSLineBreakMode.byWordWrapping
        cell.textLabel!.attributedText = customTextSettingService.getAttributedString(dataText!)
        print("cell\(cell.textLabel!.attributedText )")
        return cell
    }
    
    func parseSongUrl() -> String {
        let properties = comment.components(separatedBy: "\n")
        for property in properties {
            if property.contains("mediaUrl"){
                return property.components(separatedBy: "Url=")[1]
            }
        }
        return ""
    }
    
    func loadYoutube(url: String) {
        player.playerVars = ["rel" : 0 as AnyObject,
                             "showinfo" : 0 as AnyObject,
                             "modestbranding": 1 as AnyObject,
                             "playsinline" : 1 as AnyObject,
                             "autoplay" : 1 as AnyObject]
        let myVideoURL = URL(string: url)
        player.loadVideoURL(myVideoURL!)
    }
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String]) {
        element = elementName
        print("element:\(element)")
        attribues = attributeDict as NSDictionary
        print("attribues:\(attribues)")
        
    }
    
    fileprivate func addShareBarButton() {
        self.navigationController!.navigationBar.tintColor = UIColor.gray
        let doneButton = UIBarButtonItem(image: #imageLiteral(resourceName: "Share"), style: UIBarButtonItemStyle.plain, target: self, action: #selector(SongWithVideoViewController.share))
        navigationItem.rightBarButtonItem = doneButton
    }
    
    func fullScreen() {
        performSegue(withIdentifier: "fullScreen", sender: self)
    }
    
    @IBAction func playOrStop(_ sender: Any) {
        setAction()
    }
    
    func presentation() {
        performSegue(withIdentifier: "presentation", sender: self)
    }
    
    func setAction() {
        if hadYoutubeLink {
            if play {
                play = false
                actionButton.isHidden = true
                floatingbutton.isHidden = false
                player.isHidden = true
                playerHeight.constant = 0
                player.stop()
            } else {
                play = true
                actionButton.setImage(UIImage(named: "stop"), for: UIControlState())
                floatingbutton.isHidden = true
                actionButton.isHidden = false
                player.isHidden = false
                playerHeight.constant = 250
                player.play()
            }
        } else {
            presentation()
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any!) {
        if (segue.identifier == "fullScreen") {
            let transition = CATransition()
            transition.duration = 0.75
            transition.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
            transition.type = kCATransitionFade
            self.navigationController!.view.layer.add(transition, forKey: nil)
            let fullScreenController = segue.destination as! FullScreenViewController
            fullScreenController.cells = getAllCells()
            fullScreenController.songName = songName
            fullScreenController.authorName = authorName
        } else if (segue.identifier == "presentation") {
            let presentationViewController = segue.destination as! PresentationViewController
            presentationViewController.verseOrder = verseOrder
            presentationViewController.songLyrics = songLyrics
            presentationViewController.songName = songName
            presentationViewController.authorName = authorName
        }
    }
    
    func share() {
        let emailMessage = getObjectToShare()
        let messagerMessage = getMessageToShare()
        let firstActivityItem = CustomProvider(placeholderItem: "Default" as AnyObject, messagerMessage: messagerMessage.string, emailMessage: emailMessage.string)
        if let myWebsite = URL(string: "https://itunes.apple.com/us/app/tamil-christian-worship-songs/id1066174826?mt=8") {
            let objectsToShare = [firstActivityItem, myWebsite] as [Any]
            let activityVC = UIActivityViewController(activityItems: objectsToShare, applicationActivities: nil)
            activityVC.setValue("Tamil Christian Worship Songs " + songName, forKey: "Subject")
            activityVC.excludedActivityTypes = [UIActivityType.airDrop, UIActivityType.postToWeibo, UIActivityType.postToVimeo, UIActivityType.postToTencentWeibo, UIActivityType.postToFlickr, UIActivityType.assignToContact, UIActivityType.addToReadingList, UIActivityType.copyToPasteboard, UIActivityType.postToFacebook, UIActivityType.saveToCameraRoll, UIActivityType.print, UIActivityType.openInIBooks, UIActivityType(rawValue: "Reminders")]
            
            activityVC.popoverPresentationController?.sourceView = self.view
            activityVC.popoverPresentationController?.barButtonItem = navigationItem.rightBarButtonItem
            self.present(activityVC, animated: true, completion: nil)
        }
    }
    
    class CustomProvider : UIActivityItemProvider {
        var messagerMessage : String!
        var emailMessage : String!
        
        init(placeholderItem: AnyObject, messagerMessage : String, emailMessage : String) {
            super.init(placeholderItem: placeholderItem)
            self.messagerMessage = messagerMessage
            self.emailMessage = emailMessage
        }
        
        override func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivityType) -> Any? {
            if activityType == UIActivityType.message {
                return messagerMessage as AnyObject?
            } else if activityType == UIActivityType.mail {
                return emailMessage as AnyObject?
            } else if activityType == UIActivityType.postToTwitter {
                return NSLocalizedString(messagerMessage, comment: "comment")
            }else {
                return emailMessage as AnyObject?
            }
        }
    }
    
    func getObjectToShare() -> NSMutableAttributedString {
        let objectString: NSMutableAttributedString = NSMutableAttributedString()
        objectString.append(NSAttributedString(string: "<html><body>"))
        objectString.append(NSAttributedString(string: "<h1><a href=\"https://itunes.apple.com/us/app/tamil-christian-worship-songs/id1066174826?mt=8\">Tamil Christian Worship Songs</a></h1>"))
        objectString.append(NSAttributedString(string: "<h2>\(songName)</h2>"))
        for verseOrder in verseOrderList {
            let key: String = (verseOrder as! String).lowercased()
            let dataText: String? = listDataDictionary[key] as? String
            let texts = parseString(text: dataText!)
            print("verseOrder \(verseOrder)")
            for text in texts {
                objectString.append(NSAttributedString(string: text))
                objectString.append(NSAttributedString(string: "<br/>"))
            }
        }
        objectString.append(NSAttributedString(string: "</body></html>"))
        return objectString
    }
    
    func parseString(text: String) -> [String] {
        var parsedText = text.replacingOccurrences(of: "{/y}", with: "{y} ")
        print(parsedText)
        parsedText.append("{y}")
        return parsedText.components(separatedBy: "{y}")
    }
    
    func getMessageToShare() -> NSMutableAttributedString {
        let objectString: NSMutableAttributedString = NSMutableAttributedString()
        objectString.append(NSAttributedString(string: "Tamil Christian Worship Songs\n\n"))
        objectString.append(NSAttributedString(string: "\n\(songName)\n\n"))
        for verseOrder in verseOrderList {
            let key: String = (verseOrder as! String).lowercased()
            let dataText: String? = listDataDictionary[key] as? String
            let texts = parseString(text: dataText!)
            print("verseOrder \(verseOrder)")
            for text in texts {
                objectString.append(NSAttributedString(string: text))
            }
            objectString.append(NSAttributedString(string: "\n\n"))
        }
        return objectString
    }
    
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        text = string
        print("string:\(string)")
        let data = string.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        print("data:\(data)")
        if (!data.isEmpty) {
            if element == "verse" {
                let verseType = (attribues.object(forKey: "type") as! String).lowercased()
                let verseLabel = attribues.object(forKey: "label")as! String
                //lyricsData.append(data);
                listDataDictionary.setObject(data as String, forKey: verseType.appending(verseLabel) as NSCopying)
                if(verseOrderList.count < 1){
                    parsedVerseOrderList.add(verseType + verseLabel)
                    print("parsedVerseOrder:\(parsedVerseOrderList)")
                }
            }
        }
    }
    
    override func didRotate(from fromInterfaceOrientation: UIInterfaceOrientation) {
        self.onChangeOrientation(orientation: UIDevice.current.orientation)
    }
    
    func onChangeOrientation(orientation: UIDeviceOrientation) {
        switch orientation {
        case .portrait:
            self.navigationController?.setNavigationBarHidden(false, animated: true)
        case .landscapeRight:
            self.navigationController?.setNavigationBarHidden(true, animated: true)
            fullScreen()
        case .landscapeLeft:
            self.navigationController?.setNavigationBarHidden(true, animated: true)
            fullScreen()
        default:
            self.navigationController?.setNavigationBarHidden(false, animated: true)
        }
    }
    
    
    func getAllCells() -> [UITableViewCell] {
        
        var cells = [UITableViewCell]()
        // assuming tableView is your self.tableView defined somewhere
        for i in 0...self.verseOrderList.count-1
        {
            let key: String = (verseOrderList[i] as! String).lowercased()
            let dataText: NSString? = listDataDictionary[key] as? NSString
            let cell = UITableViewCell()
            let fontSize = self.preferences.integer(forKey: "fontSize")
            cell.textLabel?.font = UIFont.systemFont(ofSize: CGFloat(fontSize + 5))
            cell.textLabel!.numberOfLines = 0
            cell.textLabel!.lineBreakMode = NSLineBreakMode.byWordWrapping
            cell.textLabel!.attributedText = customTextSettingService.getAttributedString(dataText!);
            cells.append(cell)
        }
        return cells
    }
    
}

