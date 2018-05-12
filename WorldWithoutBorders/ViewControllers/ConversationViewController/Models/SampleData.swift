//
//  SampleData.swift
//  WorldWithoutBorders
//
//  Created by Clifford Yin on 2/11/18.
//  Copyright © 2018 Clifford Yin. All rights reserved.
//

import Foundation
import MessageKit
import CoreLocation
import Firebase
import FirebaseStorage
import FirebaseStorageUI

/* Structure that contains the messages of the selected conversation */
final class SampleData {
    
    static let shared = SampleData()
    
    private init() {
    }
    
    // MARK: Properties
    
    let placehold = UIImage(named: "Demo")
    let ref = Database.database().reference()
    let storage = Storage.storage()
    var storageRef: StorageReference!
    var messages = [Message]()
    var user: Sender!
    var chatter: Sender!
    var selfImage: UIImage!
    var chatterImage: UIImage!
    
    var currentSender: Sender {
        return user
    }
    
    // MARK: Message functions
    
    // Uses the current conversation ID to locate messages
    func instantiate(_ convoID: String) {
        self.ref.child("conversations").observeSingleEvent(of: .value) { (snapshot: DataSnapshot!) in
            self.user = Sender(id: (Auth.auth().currentUser?.uid)!, displayName: CurrentUser.sharedInstance.user.profile.name)
            self.chatter = Sender(id: CurrentChat.sharedInstance.otherUser, displayName: CurrentChat.sharedInstance.otherUserName)
            var convoTemp = [String]()
            for item in snapshot.children {
                let childSnapshot = snapshot.childSnapshot(forPath: (item as AnyObject).key)
                let convo = childSnapshot.key
                convoTemp.append(convo)
            }
            if (convoTemp.contains(convoID)) {
                self.makeMessages(key: convoID)
            } else {
                self.messages = []
            }
        }
    }
    
    // Pulls the message data and creates messages
    func makeMessages(key: String) {
        self.ref.child("conversations").child(key).observeSingleEvent(of: .value) { (snapshot: DataSnapshot!) in
            self.storageRef = self.storage.reference()
            var messageTemp = [Message]()
            for item in snapshot.children {
                
                var messaging = ""
                var uiding = ""
                var photoing = ""
                var naming = ""
                var imageUrl = ""
                let childSnapshot = snapshot.childSnapshot(forPath: (item as AnyObject).key)
                let values = childSnapshot.value as? NSDictionary
                if (values?["photoUrl"] != nil) { // Retrieve photo URL
                    photoing = values?["photoUrl"] as! String
                }
                if (values?["name"] != nil) { // Pull other properties, such as name
                    naming = values?["name"] as! String
                }
                if (values?["text"] != nil) {
                    messaging = values?["text"] as! String
                } else if (values?["text"] == nil) {
                    imageUrl = values?["imageUrl"] as! String
                }
                if (values?["uid"] != nil) {
                    uiding = values?["uid"] as! String
                }
                var sending = Sender(id: "", displayName: "")
                if (uiding == self.user.id) { // If is self, use own pic
                    sending = self.user
                    let url = URL(string: photoing)
                    let data = NSData(contentsOf: url!)
                    let image = UIImage(data: data as! Data)!
                    self.selfImage = image
                } else if (uiding == self.chatter.id) { // If is convo participant, use their pic
                    sending = self.chatter
                    let url = URL(string: photoing)
                    let data = NSData(contentsOf: url!)
                    let image = UIImage(data: data as! Data)!
                    self.chatterImage = image
                }
                let uniqueId = ""
                if (imageUrl == "") {
                    let put = Message(text: messaging, sender: sending, messageId: uniqueId, date: Date())
                    messageTemp.append(put)
                } else {
                    
                    var imaged = UIImage()
                    var imageSub = UIImage()
                    // Download image from Google
                    let gsReference = self.storage.reference(forURL: imageUrl)
                    gsReference.getData(maxSize: 1 * 2048 * 2048) { data, error in
                        if error != nil {
                            print("error: \(error)")
                        } else {
                            imaged = UIImage(data: data!)! // Convert image to data
                            imageSub = self.resizeImage(image: imaged, newWidth: 360) as! UIImage
                            let put = Message(image: imaged, sender: sending, messageId: uniqueId, date: Date())
                            messageTemp.append(put)
                        }
                    }
                }
            }
            // Allow process to run, then assign messages
            let when = DispatchTime.now() + 1
            DispatchQueue.main.asyncAfter(deadline: when) {
                messageTemp.reverse()
                self.messages = messageTemp
            }
        }
    }
    
    // This is for when the user is initially loading the messages in a convo
    func getMessages(count: Int, completion: ([Message]) -> Void) {
        var returnMessages: [Message] = []
        for i in 0..<count {
            returnMessages.append(self.messages[i])
        }
        returnMessages.reverse() // Because retrieving the data arranges it from earliest to latest
        completion(returnMessages)
    }
    
    // This is when the user seeks to load more additional messages, and it pulls from the earlier data sent
    func fifoMessages(count: Int, index: Int, completion: ([Message]) -> Void) {
        var returnMessages: [Message] = []
        for i in index..<(count+index) { // Only attempts to load certain number of messages, max 10
            returnMessages.append(self.messages[i])
        }
        returnMessages.reverse()
        completion(returnMessages)
    }
    
    // Scale the image if needed
    func resizeImage(image: UIImage, newWidth: CGFloat) -> UIImage? {
        let scale = newWidth / image.size.width
        let newHeight = image.size.height * scale
        UIGraphicsBeginImageContext(CGSize(width: newWidth, height: newHeight))
        image.draw(in: CGRect(x: 0, y: 0, width: newWidth, height: newHeight))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage
    }
    
    // MARK: MessageKit methods/demo data source
    
    var now = Date()
    
    let messageTypes = ["Text", "Text", "Text", "AttributedText", "Photo", "Video", "Location", "Emoji"]
    
    let attributes = ["Font1", "Font2", "Font3", "Font4", "Color", "Combo"]
    
    let emojis = [
        "👍",
        "👋",
        "👋👋👋",
        "😱😱",
        "🎈",
        "🇧🇷"
    ]

    func attributedString(with text: String) -> NSAttributedString {
        let nsString = NSString(string: text)
        var mutableAttributedString = NSMutableAttributedString(string: text)
        let randomAttribute = Int(arc4random_uniform(UInt32(attributes.count)))
        let range = NSRange(location: 0, length: nsString.length)
        
        switch attributes[randomAttribute] {
        case "Font1":
            mutableAttributedString.addAttribute(NSAttributedStringKey.font, value: UIFont.preferredFont(forTextStyle: .body), range: range)
        case "Font2":
            mutableAttributedString.addAttributes([NSAttributedStringKey.font: UIFont.monospacedDigitSystemFont(ofSize: UIFont.systemFontSize, weight: UIFont.Weight.bold)], range: range)
        case "Font3":
            mutableAttributedString.addAttributes([NSAttributedStringKey.font: UIFont.boldSystemFont(ofSize: UIFont.systemFontSize)], range: range)
        case "Font4":
            mutableAttributedString.addAttributes([NSAttributedStringKey.font: UIFont.italicSystemFont(ofSize: UIFont.systemFontSize)], range: range)
        case "Color":
            mutableAttributedString.addAttributes([NSAttributedStringKey.foregroundColor: UIColor.red], range: range)
        case "Combo":
            let msg9String = "Use .attributedText() to add bold, italic, colored text and more..."
            let msg9Text = NSString(string: msg9String)
            let msg9AttributedText = NSMutableAttributedString(string: String(msg9Text))
            
            msg9AttributedText.addAttribute(NSAttributedStringKey.font, value: UIFont.preferredFont(forTextStyle: .body), range: NSRange(location: 0, length: msg9Text.length))
            msg9AttributedText.addAttributes([NSAttributedStringKey.font: UIFont.monospacedDigitSystemFont(ofSize: UIFont.systemFontSize, weight: UIFont.Weight.bold)], range: msg9Text.range(of: ".attributedText()"))
            msg9AttributedText.addAttributes([NSAttributedStringKey.font: UIFont.boldSystemFont(ofSize: UIFont.systemFontSize)], range: msg9Text.range(of: "bold"))
            msg9AttributedText.addAttributes([NSAttributedStringKey.font: UIFont.italicSystemFont(ofSize: UIFont.systemFontSize)], range: msg9Text.range(of: "italic"))
            msg9AttributedText.addAttributes([NSAttributedStringKey.foregroundColor: UIColor.red], range: msg9Text.range(of: "colored"))
            mutableAttributedString = msg9AttributedText
        default:
            fatalError("Unrecognized attribute for mock message")
        }
        
        return NSAttributedString(attributedString: mutableAttributedString)
    }
    
    func getAvatarFor(sender: Sender) -> Avatar {
        
        switch sender {
        case user:
            print("user avatar")
            return Avatar(image: selfImage, initials: "DL")
        case chatter:
            print("chatter avatar")
            return Avatar(image: chatterImage, initials: "S")
        default:
            print("default avatar")
            return Avatar(image: placehold, initials: "QQ")
        }
    }
}

