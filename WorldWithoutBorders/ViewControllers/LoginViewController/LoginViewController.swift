//
//  LoginViewController.swift
//  WorldWithoutBorders
//
//  Created by Clifford Yin on 2/8/18.
//  Copyright © 2018 Clifford Yin. All rights reserved.
//

import UIKit
import GoogleSignIn
import Firebase
import FirebaseDatabase
import FirebaseAuth
import NVActivityIndicatorView
import Hero

/* The opening login controller, regardless of whether or not a school is assigned yet. */
class LoginViewController: UIViewController, GIDSignInUIDelegate, GIDSignInDelegate {
    
    // MARK: Properties
    
    var ref: DatabaseReference!
    
    @IBOutlet weak var signin: GIDSignInButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.ref = Database.database().reference()
        // Attach delegates for Google SignIn
        GIDSignIn.sharedInstance().uiDelegate = self
        GIDSignIn.sharedInstance().delegate = self
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: Google Sign-In methods
    
    // Perform sign-in
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
        // Animate sign-in indicator
        let frame = CGRect(x: self.signin.frame.midX - 45, y: self.signin.frame.midY - 45, width: 90, height: 90)
        let activity = NVActivityIndicatorView(frame: frame, type: NVActivityIndicatorType(rawValue: 5), color: .blue, padding: nil)
        self.view.addSubview(activity)
        activity.startAnimating()
        
        // If any error, stop and print the error
        if let error = error {
            print("\(error.localizedDescription)")
            activity.stopAnimating()
        } else {
            // Pull data from signed-in users here.
            let userId = user.userID                  // For client-side use
            let idToken = user.authentication.idToken // Safe to send to the server
            let fullName = user.profile.name
            let givenName = user.profile.givenName
            let familyName = user.profile.familyName
            let email = user.profile.email
            CurrentUser.sharedInstance.instantiate(user)
            guard let authentication = user.authentication else { return }
            let credential = GoogleAuthProvider.credential(withIDToken: authentication.idToken,
                                                           accessToken: authentication.accessToken)
            
            // Check if sign-in successful with token
            Auth.auth().signIn(with: credential) { (user, error) in
                if let error = error {
                    activity.stopAnimating()
                    return
                }
                self.checkExist()
            }
        }
    }
    
    // Perform signing-out
    func sign(_ signIn: GIDSignIn!, didDisconnectWith user: GIDGoogleUser!,
                            withError error: Error!) {
            // Perform any operations when the user disconnects from app here.
            // ...
        let firebaseAuth = Auth.auth()
            do {
                try firebaseAuth.signOut()
            } catch let signOutError as NSError {
                print ("Error signing out: %@", signOutError)
            }
        
        }
    
    // MARK: IBOutlets/Actions
    
    // Check if data for this user exists in database
    func checkExist() {
        
        let id = Auth.auth().currentUser?.uid
        self.ref.child("user-data").observeSingleEvent(of: .value, with: { (snapshot) in
            if snapshot.hasChild(id!){
                // Segue to main View if so
                self.performSegue(withIdentifier: "toHome", sender: self)
            } else {
                // Allow them to register if not
                self.performSegue(withIdentifier: "toSchool", sender: self)
            }
        })
    }
}

