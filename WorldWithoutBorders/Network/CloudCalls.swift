//
//  CloudCalls.swift
//  WorldWithoutBorders
//
//  Created by Clifford Yin on 2/14/18.
//  Copyright © 2018 Clifford Yin. All rights reserved.
//

import Foundation
import Firebase

protocol ResponseDelegate {
    func response(success: String)
}

protocol ResponseDelegate2 {
    func response2(success: String)
}

protocol ResponseDelegate3 {
    func response3(success: String)
}

/* This class handles all the Firebase cloud function calls, such as signing users up, adding friends, and retrieving unread messages. */
class CloudCalls {
    
    static let sharedInstance = CloudCalls()
    
    fileprivate init () {
        
    }
    
    // MARK: Properties
    
    var delegate: ResponseDelegate!
    var delegate2: ResponseDelegate2!
    var delegate3: ResponseDelegate3!
    
    let ref = Database.database().reference()
    var response: String!
    var uid: String!
    var actioning: String!
    
    // MARK: Actions
    // Different variations because of different view controllers calling these functions
    
    // Pushes request to Firebase, cloud function runs, success/fail is returned
    func runCommand(action: String, params: NSDictionary) {
        self.uid = Auth.auth().currentUser?.uid
        let requestRef = Database.database().reference().child("function-requests").childByAutoId()
        var myRequestObject = ["action": action, "params": params, "uid": uid] as! NSDictionary
        if (action == "sendMessage") {
            myRequestObject = ["action": action, "params": params, "uid": uid, "response": "Success"] as! NSDictionary
        }
        requestRef.setValue(myRequestObject) { (error, ref) -> Void in
            // Finished pushing object
            if error != nil {
                
            } else {
                // Start watching for change in the request object to see result
                requestRef.observe(.value) { (snapshot: DataSnapshot!) in
                    let dict = snapshot.value as? [String : AnyObject] ?? [:]
                    if dict["response"] != nil {
                        // CloudCall success
                        self.delegate.response(success: action)
                    } else if dict["error"] != nil {
                        // CloudCall fail
                        self.delegate.response(success: "fail")
                    }
                }
            }
        }
    }
    
    func runCommand2(action: String, params: NSDictionary) {
        self.uid = Auth.auth().currentUser?.uid
        let requestRef = Database.database().reference().child("function-requests").childByAutoId()
        var myRequestObject = ["action": action, "params": params, "uid": uid] as! NSDictionary
        if (action == "sendMessage") {
            myRequestObject = ["action": action, "params": params, "uid": uid, "response": "Success"] as! NSDictionary
        }
        requestRef.setValue(myRequestObject) { (error, ref) -> Void in
            // Finished pushing object
            if error != nil {
                
            } else {
                requestRef.observe(.value) { (snapshot: DataSnapshot!) in
                    let dict = snapshot.value as? [String : AnyObject] ?? [:]
                    if dict["response"] != nil {
                        // CloudCall success
                        self.delegate2.response2(success: action)
                    } else if dict["error"] != nil {
                        // CloudCall fail
                        self.delegate2.response2(success: "fail")
                    }
                }
            }
        }
    }
    
    func runCommand3(action: String, params: NSDictionary) {
        self.uid = Auth.auth().currentUser?.uid
        let requestRef = Database.database().reference().child("function-requests").childByAutoId()
        var myRequestObject = ["action": action, "params": params, "uid": uid] as! NSDictionary
        if (action == "sendMessage") {
            myRequestObject = ["action": action, "params": params, "uid": uid, "response": "Success"] as! NSDictionary
        }
        requestRef.setValue(myRequestObject) { (error, ref) -> Void in
            if error != nil {
                
            } else {
                requestRef.observe(.value) { (snapshot: DataSnapshot!) in
                    let dict = snapshot.value as? [String : AnyObject] ?? [:]
                    if dict["response"] != nil {
                        self.delegate3.response3(success: action)
                    } else if dict["error"] != nil {
                        self.delegate3.response3(success: "fail")
                    }
                }
            }
        }
    }
}
