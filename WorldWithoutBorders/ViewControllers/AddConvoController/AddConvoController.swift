//
//  AddConvoController.swift
//  WorldWithoutBorders
//
//  Created by Clifford Yin on 2/22/18.
//  Copyright © 2018 Clifford Yin. All rights reserved.
//

import UIKit
import Firebase
import NVActivityIndicatorView

protocol AddConvoDelegate {
    func addConvo(new: String)
}

/* Controller that allows for adding of conversation through an email */
class AddConvoController: UIViewController {

    var delegate: AddConvoDelegate!
    var ref = Database.database().reference()
    
    @IBOutlet weak var emailField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // Adds a user through email
    @IBAction func addConvo(_ sender: Any) {
        let frame = CGRect(x: self.view.frame.midX - 60, y: self.view.frame.midY - 60, width: 120, height: 120)
        let activity = NVActivityIndicatorView(frame: frame, type: NVActivityIndicatorType(rawValue: 3), color: .blue, padding: nil)
        self.view.addSubview(activity)
        activity.startAnimating()
        
        self.ref.child("user-data").observeSingleEvent(of: .value) { (snapshot: DataSnapshot!) in
            
            for item in snapshot.children {
                let childSnapshot = snapshot.childSnapshot(forPath: (item as AnyObject).key)
                let uid = childSnapshot.key
                let values = childSnapshot.value as? NSDictionary
                let emailed = values?["email"] as! String
                if (self.emailField.text == emailed) {
                    self.delegate.addConvo(new: uid)
                }
            }
        }
    }
    
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
