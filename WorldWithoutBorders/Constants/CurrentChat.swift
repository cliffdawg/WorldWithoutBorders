//
//  CurrentChat.swift
//  WorldWithoutBorders
//
//  Created by Clifford Yin on 2/12/18.
//  Copyright © 2018 Clifford Yin. All rights reserved.
//

import Foundation
import Firebase
import GoogleSignIn

/* Code that constitutes the data for the current chat being displayed in ConversationViewController */
class CurrentChat {
    
    static let sharedInstance = CurrentChat()
    
    fileprivate init () {
        
    }
    
    var otherUser = ""
    var otherUserName = ""
    var convoID = ""
    let ref = Database.database().reference()
    
    // Compose the ID for the chat out of two userID's
    func instantiate(_ talking: String) {
        self.otherUser = talking
        if ((Auth.auth().currentUser?.uid)! > (talking)) {
            convoID = (Auth.auth().currentUser?.uid)! + talking
        } else {
            convoID = talking + (Auth.auth().currentUser?.uid)!
        }
        self.findName()
    }
    
    // Find the chat message store through the composed chat ID in the database
    func findName() {
        self.ref.child("user-data").observeSingleEvent(of: .value) { (snapshot: DataSnapshot!) in
            for item in snapshot.children {
                let childSnapshot = snapshot.childSnapshot(forPath: (item as AnyObject).key)
                let uid = childSnapshot.key
                if (uid == self.otherUser) {
                    let values = childSnapshot.value as? NSDictionary
                    if (values?["displayName"] != nil) {
                        self.otherUserName = values?["displayName"] as! String
                        SampleData.shared.instantiate(self.convoID)
                    }
        
                }
            }
        }
    }
}
