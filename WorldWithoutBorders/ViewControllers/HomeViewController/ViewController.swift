//
//  ViewController.swift
//  WorldWithoutBorders
//
//  Created by Clifford Yin on 2/8/18.
//  Copyright © 2018 Clifford Yin. All rights reserved.
//

import UIKit
import Firebase
import FirebaseDatabase
import BulletinBoard
import ViewAnimator
import Alamofire
import SwiftyPickerPopover
import NVActivityIndicatorView
import HGPlaceholders
import Hero

protocol RefreshControllerDelegate {
    func refresh()
}

extension ViewController: PlaceholderDelegate {
    
    func view(_ view: Any, actionButtonTappedFor placeholder: Placeholder) {
        print(placeholder.key.value)
        let table = convoTable as? TableView
        table?.showLoadingPlaceholder()
    }
    
}

/* This ViewController is the home controller of the app. It has a chat interface, represented by ConversationsViewController, stored in a child container view. Conversations can be added and schoolmates can be seen from this view. */
class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UIPopoverControllerDelegate, UIPopoverPresentationControllerDelegate, AddConvoDelegate, UITextFieldDelegate, ResponseDelegate2, DismissViewDelegate {
    
    // MARK: Properties
    
    // The user agreement
    lazy var bulletinManager: BulletinManager = {
        let page = PageBulletinItem(title: "Terms Agreement")
        page.image = UIImage(named: "Bulletin")
        page.descriptionText = "Please agree to these terms: \nI will use World Without Borders to practice my language skills and not engage in negative conduct. \nI understand that when paired with a school, all activity can be monitored by my teacher, and violation of good conduct can result in punishment. \nI understand even with cautionary measures in place, there still exists a risk of defamatory or illegal content, and accept this risk with usage. \nI am at least 14 years of age; if under 18, my parents have also read these terms and agreed with them."
        page.actionButtonTitle = "I Agree"
        page.actionHandler = { (item: PageBulletinItem) in
            item.manager?.dismissBulletin(animated: true)
        }
        let rootItem: BulletinItem = page
        return BulletinManager(rootItem: rootItem)
    }()
    
    var input = ""
    var output = ""
    var counter = 0
    var textBar: UITextField!
    var delegate: RefreshControllerDelegate!
    var ref: DatabaseReference!
    var convos = [Convo]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.convoTable.layer.masksToBounds = true
        self.convoTable.layer.cornerRadius = 5.0
        self.googleImage.layer.masksToBounds = true
        self.googleImage.layer.cornerRadius = googleImage.frame.width/2
        let table = convoTable as? TableView
        table?.placeholderDelegate = self
        table?.showLoadingPlaceholder()
        self.name.text = CurrentUser.sharedInstance.user.profile.name
        self.googleImage.image = CurrentUser.sharedInstance.unwrapImage
        ref = Database.database().reference()
        self.delegate = self.childViewControllers[0] as! RefreshControllerDelegate
        CloudCalls.sharedInstance.delegate2 = self
        checkConvo()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        agree()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: IBOutlets/Actions
    
    @IBOutlet weak var mySchool: UIButton!
    @IBOutlet weak var translateView: UIView!
    @IBOutlet weak var name: UILabel!
    @IBOutlet weak var googleImage: UIImageView!
    @IBOutlet weak var convoTable: UITableView!
    @IBOutlet weak var addConvo: UIButton!
    @IBOutlet weak var inputLanguage: UIButton!
    @IBOutlet weak var outputLanguage: UIButton!
    @IBOutlet weak var banner: UILabel!
    @IBOutlet weak var textEnter: UITextField!
    
    // If first launch, prompt the user agreement
    func agree() {
        let launchedBefore = UserDefaults.standard.bool(forKey: "launchedBefore")
        if launchedBefore {
            print("Not first launch.")
        } else {
            self.bulletinManager.backgroundViewStyle = .blurredLight
            self.bulletinManager.prepare()
            self.bulletinManager.presentBulletin(above: self)
            print("First launch, setting UserDefault.")
            UserDefaults.standard.set(true, forKey: "launchedBefore")
        }
    }
    
    
    // Show the controller to add conversations
    @IBAction func addConvo(_ sender: Any) {
        let popoverViewController = self.storyboard?.instantiateViewController(withIdentifier: "addConvo") as! AddConvoController
        popoverViewController.modalPresentationStyle = .popover
        popoverViewController.preferredContentSize = CGSize(width:200, height:200)
        popoverViewController.delegate = self
        let popoverPresentationViewController = popoverViewController.popoverPresentationController
        popoverPresentationViewController?.permittedArrowDirections = UIPopoverArrowDirection.down
        popoverPresentationViewController?.delegate = self
        popoverPresentationViewController?.sourceView = self.addConvo
        popoverPresentationViewController?.sourceRect = CGRect(x:0, y:0, width: addConvo.frame.width/2, height: 60)
        present(popoverViewController, animated: true, completion: nil)
    }
    
    // Show the list of schoolMates
    @IBAction func mySchool(_ sender: Any) {
        let popoverViewController = self.storyboard?.instantiateViewController(withIdentifier: "mySchool") as! SchoolController
        popoverViewController.modalPresentationStyle = .popover
        popoverViewController.preferredContentSize = CGSize(width:400, height:200)
        popoverViewController.delegate = self
        let popoverPresentationViewController = popoverViewController.popoverPresentationController
        popoverPresentationViewController?.permittedArrowDirections = UIPopoverArrowDirection.up
        popoverPresentationViewController?.delegate = self
        popoverPresentationViewController?.sourceView = self.mySchool
        popoverPresentationViewController?.sourceRect = CGRect(x:0, y:0, width: mySchool.frame.width/2, height: 60)
        present(popoverViewController, animated: true, completion: nil)
    }
    
    func popoverPresentationControllerDidDismissPopover(_ popoverPresentationController: UIPopoverPresentationController) {
        let blurredEffectViews = self.view.subviews.filter{$0 is UIVisualEffectView}
        blurredEffectViews.forEach{ blurView in
            blurView.removeFromSuperview()
        }
    }
    
    // Translate a string between languages
    @IBAction func translate(_ sender: Any) {
        
        if (((self.input.trimmingCharacters(in: .whitespaces).isEmpty) == false)&&((self.output.trimmingCharacters(in: .whitespaces).isEmpty) == false)) {
            // Run the translate animation indicator
            
            let frame = CGRect(x: self.translateView.frame.midX - 45, y: self.translateView.frame.midY - 45, width: 90, height: 90)
            let activity = NVActivityIndicatorView(frame: frame, type: NVActivityIndicatorType(rawValue: 5), color: .blue, padding: nil)
            self.view.addSubview(activity)
            activity.startAnimating()
            
            var sourceText = textEnter.text!
            var changed = ""
            var texted = self.textEnter.text ?? ""
            let request = Translate()
            request.translate(inputLang: self.input, outputLang: self.output, text: texted, completion: {
                (result: String) in
                changed = result
            })
            let when = DispatchTime.now() + 2
            DispatchQueue.main.asyncAfter(deadline: when) {
                self.textEnter.text = changed
                activity.stopAnimating()
            }
        } else {
            // Show a Whisper banner to prompt entering languages
        }
        
    }
    
    // Animate the translation component
    // Fix the chat offset that showing the translateView creates
    @IBAction func showTranslate(_ sender: Any) {
        let blurEffect = UIBlurEffect(style: UIBlurEffectStyle.regular)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView.frame = view.bounds
        blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(blurEffectView)
        self.view.bringSubview(toFront: self.translateView)
        let zoomAnimation = AnimationType.zoom(scale: 0.0)
        self.translateView.animate(animations: [zoomAnimation], initialAlpha: 0.5, finalAlpha: 1.0, delay: 0.0, duration: 1.0, completion: nil)
    }
    
    // Dismiss the translation component
    @IBAction func dismissTranslate(_ sender: Any) {
        let slideAnimation = AnimationType.from(direction: .left, offset: 0)
        self.translateView.animate(animations: [slideAnimation], initialAlpha: 1.0, finalAlpha: 0.0, delay: 0.0, duration: 0.5, completion: {
            self.view.sendSubview(toBack: self.translateView)
            let blurredEffectViews = self.view.subviews.filter{$0 is UIVisualEffectView}
            blurredEffectViews.forEach{ blurView in
                blurView.removeFromSuperview()
            }
        })
    }
    
    // Input language manager
    @IBAction func input(_ sender: Any) {
        let displayStringFor:((String?)->String?)? = { string in
            if let s = string {
                switch(s){
                case "en":
                    return "English"
                case "es":
                    return "Spanish"
                case "fr":
                    return "French"
                case "zh-CN":
                    return "Chinese (Simplified)"
                case "ja":
                    return "Japanese"
                case "ar":
                    return "Arabic"
                case "ko":
                    return "Korean"
                case "fa":
                    return "Persian"
                case "ru":
                    return "Russian"
                case "de":
                    return "German"
                default:
                    return s
                }
            }
            return nil
        }
        
        let languages = ["English", "Spanish", "French", "Chinese (Simplified)", "Japanese", "Arabic", "Korean", "Persian", "Russian", "German"]
        let available = ["en", "es", "fr", "zh-CN", "ja", "ar", "ko", "fa", "ru", "de"]
        let p = StringPickerPopover(title: "From Language", choices: ["en", "es", "fr", "zh-CN", "ja", "ar", "ko", "fa", "ru", "de"])
            .setDisplayStringFor(displayStringFor)
            .setDoneButton(action: {
                popover, selectedRow, selectedString in
                self.change1(language: languages[selectedRow])
                self.input = available[selectedRow]
                })
            .setCancelButton(action: { _, _, _ in })
        p.appear(originView: self.inputLanguage, baseViewController: self)
    }
    
    // Output language manager
    @IBAction func output(_ sender: Any) {
        let displayStringFor:((String?)->String?)? = { string in
            if let s = string {
                switch(s){
                case "en":
                    return "English"
                case "es":
                    return "Spanish"
                case "fr":
                    return "French"
                case "zh-CN":
                    return "Chinese (Simplified)"
                case "ja":
                    return "Japanese"
                case "ar":
                    return "Arabic"
                case "ko":
                    return "Korean"
                case "fa":
                    return "Persian"
                case "ru":
                    return "Russian"
                case "de":
                    return "German"
                default:
                    return s
                }
            }
            return nil
        }
        
        let languages = ["English", "Spanish", "French", "Chinese (Simplified)", "Japanese", "Arabic", "Korean", "Persian", "Russian", "German"]
        let available = ["en", "es", "fr", "zh-CN", "ja", "ar", "ko", "fa", "ru", "de"]
        let p = StringPickerPopover(title: "To Language", choices: ["en", "es", "fr", "zh-CN", "ja", "ar", "ko", "fa", "ru", "de"])
            .setDisplayStringFor(displayStringFor)
            .setDoneButton(action: {
                popover, selectedRow, selectedString in
                self.change2(language: languages[selectedRow])
                self.output = available[selectedRow]
            })
            .setCancelButton(action: { _, _, _ in })
        p.appear(originView: self.inputLanguage, baseViewController: self)
    }
    
    // Set input language
    func change1(language: String) {
        let when = DispatchTime.now() + 0.1
        DispatchQueue.main.asyncAfter(deadline: when) {
            self.inputLanguage.setTitle(language, for: .normal)
        }
    }
    
    // Set output language
    func change2(language: String) {
        let when = DispatchTime.now() + 0.1
        DispatchQueue.main.asyncAfter(deadline: when) {
            self.outputLanguage.setTitle(language, for: .normal)
        }
    }
    
    func checkConvo() {
        let id = Auth.auth().currentUser?.uid
        ref.child("user-data").child(id!).observe(.value) { (snapshot: DataSnapshot!) in
            if snapshot.hasChild("conversations"){
                self.loadConvos() // If conversations exist, load
            } else {
            
            }
        }
    }
    
    // Loads the conversations from database
    func loadConvos() {
        let id = Auth.auth().currentUser?.uid
        ref.child("user-data").child(id!).child("conversations").observeSingleEvent(of: .value) { (snapshot: DataSnapshot!) in
                self.convos.removeAll()
                var convoDict = [String: Int]() // Stores them in pairs of UID-unread count
                for item in snapshot.children {
                    let childSnapshot = snapshot.childSnapshot(forPath: (item as AnyObject).key)
                    let convo = childSnapshot.value as? NSDictionary
                    let user = convo?["recipientUID"] as! String
                    var unread = 0
                    if (convo?["unreadMessages"] != nil) {
                        unread = convo?["unreadMessages"] as! Int
                    }
                    convoDict[user] = unread
                }
            self.loadConvo(convoStore: convoDict)
        }
    }
    
    // Loads all the data of each conversation with paired values
    func loadConvo(convoStore: [String: Int]) {
        self.ref.child("user-data").observe(.value) { (snapshot: DataSnapshot!) in
            var convosTemp = [Convo]()
            var convoNames = [String]()
            for pair in convoStore {
                
                let userID = pair.key
                let addUnread = pair.value
                for item in snapshot.children {
                    
                    let childSnapshot = snapshot.childSnapshot(forPath: (item as AnyObject).key)
                    let uid = childSnapshot.key
                    if (uid == userID) {
                        var image = UIImage()
                        let values = childSnapshot.value as? NSDictionary
                        
                        if (values?["photoURL"] != nil) {
                            let photoURL = values?["photoURL"] as! String
                            let url = URL(string: photoURL)
                            let data = NSData(contentsOf: url!)
                            image = UIImage(data: data as! Data)!
                        }
                        let name = values?["displayName"] as! String
                        let new = Convo(userImage: image, named: name, unread: addUnread, id: uid)
                        print("New convo")
            
                        if (new.unreadMessages != 0) { // If there are unread messages, append to front
                            convosTemp.insert(new, at: 0)
                            convoNames.insert(uid, at: 0)
                        } else {
                            convosTemp.append(new)
                            convoNames.append(uid)
                        }
                    }
                }
            }
            self.convos = convosTemp
            CurrentUser.sharedInstance.convos = convoNames
            self.convoTable.reloadData()
        }
    }
    
    // This is the delegate for the addConvo controller.
    // CloudCalls runs all the cloud functions in the database
    func addConvo(new: String) {
        CloudCalls.sharedInstance.runCommand2(action: "addConversation", params: ["recipientUID": new])
    }
    
    // If adding conversation succeeds, this return function is triggered
    func response2(success: String) {
        if success == "addConversation" {
            self.dismiss(animated: true, completion: nil)
            self.dismiss()
        } else if success == "fail" {
            print("Operation failed")
        }
    }
    
    // Dismiss the list of schoolmates
    func dismiss(){
        // Problems only emerge with duplicates
        let when = DispatchTime.now() + 1
        DispatchQueue.main.asyncAfter(deadline: when) {
            self.convoTable.reloadData()
        }
        // Use Whisper to show that convo is added
    }
    
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        return .none
    }
    
    // MARK: TableView methods
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
    
    func tableView(_ convoTable : UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.convos.count
    }
    
    func tableView(_ convoTable: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = convoTable.dequeueReusableCell(withIdentifier: "convoCell", for: indexPath) as! ConvoCell
            cell.name.text = convos[indexPath.row].name
            cell.profilePic.image = convos[indexPath.row].image
            cell.unreadCount.layer.masksToBounds = true
            cell.unreadCount.layer.cornerRadius = 5.0
            cell.unreadCount.text = String(convos[indexPath.row].unreadMessages)
            cell.profilePic.layer.masksToBounds = true
            cell.profilePic.layer.cornerRadius = cell.profilePic.frame.width/2.75
            // Bolds name and displays unread count if available
            if (convos[indexPath.row].unreadMessages != 0) {
                cell.unreadCount.alpha = 1.0
                cell.name.font = .boldSystemFont(ofSize: 15)
            } else {
                cell.unreadCount.alpha = 0.0
                cell.name.font = .systemFont(ofSize: 15)
            }
            cell.unreadCount.text = "\(String(convos[indexPath.row].unreadMessages)) new"
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let id = convos[indexPath.row].uid
        CurrentChat.sharedInstance.instantiate(id!)
        delegate.refresh()
        self.view.sendSubview(toBack: self.banner)
    }
}

