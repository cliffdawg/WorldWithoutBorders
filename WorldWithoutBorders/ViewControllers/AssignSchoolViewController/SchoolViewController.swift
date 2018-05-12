//
//  SignupViewController.swift
//  WorldWithoutBorders
//
//  Created by Clifford Yin on 2/8/18.
//  Copyright © 2018 Clifford Yin. All rights reserved.
//

import UIKit
import Firebase
import NVActivityIndicatorView

/* Controller that handles registering user for school */
class SchoolViewController: UIViewController, ResponseDelegate {

    // MARK: Properties
    
    var codes = [String]()
    let ref = Database.database().reference()
    
    @IBOutlet weak var schoolCode: UITextField!
    @IBOutlet weak var schoolButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        CloudCalls.sharedInstance.delegate = self
        load()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: IBOutlets/Actions
    
    // Sign the user up in that school
    @IBAction func pressSubmit(_ sender: Any) {
        if (self.codes.contains(schoolCode.text!)) {
            let frame = CGRect(x: self.schoolButton.frame.midX - 45, y: self.schoolButton.frame.midY - 45, width: 90, height: 90)
            let activity = NVActivityIndicatorView(frame: frame, type: NVActivityIndicatorType(rawValue: 5), color: .blue, padding: nil)
            self.view.addSubview(activity)
            activity.startAnimating()
            CloudCalls.sharedInstance.runCommand(action: "registerInSchool", params: ["schoolCode": schoolCode.text])
        } else {
            // Use Whisper to notify fail
        }
    }
    
    // Closure return for attempt to sign user in school
    func response(success: String) {
        if (success == "registerInSchool") {
            // Go to the main view
            performSegue(withIdentifier: "fromSchoolToHome", sender: self)
        } else if (success == "fail") {
            // Use Whisper to notify failure
        }
    }
    
    // Put in new user data in database
    func load() {
        ref.child("schools").observe(.value) { (snapshot: DataSnapshot!) in
            var schoolsTemp = [String]()
            for item in snapshot.children {
                
                let childSnapshot = snapshot.childSnapshot(forPath: (item as AnyObject).key)
                let schoolName = childSnapshot.key
                schoolsTemp.append(schoolName)
            }
            self.codes = schoolsTemp
            print(self.codes)
        }
        ref.child("user-data").child((Auth.auth().currentUser?.uid)!).setValue(["displayName": "\(CurrentUser.sharedInstance.user.profile.name!)", "email": "\(CurrentUser.sharedInstance.user.profile.email!)", "registered": "true", "photoURL": "\(CurrentUser.sharedInstance.urled!)", "timezone": String(TimeZone.current.identifier)])
    }
    
    // Alternative method
    func putData(school: String) {
        let schoolcode = String(school)
        let id = Auth.auth().currentUser?.uid
        var bodyString = ""
        let scriptUrl = "https://penpalapp-6020c.firebaseio.com/"
        var urlWithParams = scriptUrl + "user-data/\(id as! String).json"
        let timezone = String(TimeZone.current.identifier)
        let name = String(CurrentUser.sharedInstance.user.profile.name!)
        let email = String(CurrentUser.sharedInstance.user.profile.email!)
        let photo = String(CurrentUser.sharedInstance.user.profile.imageURL(withDimension: 150).absoluteString)
        let register = "true"
        bodyString = "{ \"displayName\": \"\(name)\", \"email\": \"\(email)\", \"photoURL\": \"\(photo)\", \"registered\": \"\(register)\", \"uid\": \"\(id as! String)\", \"timezone\": \"\(timezone)\", \"schoolCode\": \"\(schoolcode)\" }"
        let myUrl = URL(string: urlWithParams);
        var request = URLRequest(url:myUrl!);
        request.httpBody = bodyString.data(using: .utf8)
        // POST used to create, PUT used to create or update
        request.httpMethod = "PUT"
        let task = URLSession.shared.dataTask(with: request) {
            data, response, error in
            if error != nil
            {
                print("error=\(error)")
                return
            }
            let responseString = NSString(data: data!, encoding: String.Encoding.utf8.rawValue)
            print("responseString = \(responseString)")
        }
        task.resume()
        performSegue(withIdentifier: "fromSchoolToHome", sender: self)
    }
}

