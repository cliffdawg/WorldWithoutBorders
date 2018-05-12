//
//  SchoolController.swift
//  WorldWithoutBorders
//
//  Created by Clifford Yin on 3/18/18.
//  Copyright © 2018 Clifford Yin. All rights reserved.
//

import UIKit
import Firebase
import NVActivityIndicatorView
import ViewAnimator

protocol DismissViewDelegate {
    func dismiss()
}

/* ViewController that displays a list of classmates that can possibly be added as a convo */
class SchoolController: UIViewController, UITableViewDelegate, UITableViewDataSource, InitialDismissDelegate {
    
    // MARK: Properties
    
    let ref = Database.database().reference()
    var delegate: DismissViewDelegate!
    private let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .gray)
    
    private func setupActivityIndicator() {
        activityIndicator.center = CGPoint(x: view.center.x, y: 100.0)
        activityIndicator.hidesWhenStopped = true
        view.addSubview(activityIndicator)
        activityIndicator.startAnimating()
    }
    
    var schoolMates = [SchoolObject]() {
        didSet {
            
            self.setupActivityIndicator()
            self.activityIndicator.stopAnimating()
            self.schoolTable.animateViews(animations: [AnimationType.from(direction: .right, offset: self.view.frame.width - 60)], initialAlpha: 0.0, finalAlpha: 1.0, delay: 0, duration: 0.5, animationInterval: 0.1, completion: nil)
            schoolTable.alpha = 1.0
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.schoolTable.alpha = 0.0
        self.getSchool()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: IBOutlets/Actions
    
    @IBOutlet weak var schoolTable: UITableView!
    
    func getSchool() {
        let id = Auth.auth().currentUser?.uid
        ref.child("user-data").child(id!).observe(.value) { (snapshot: DataSnapshot!) in
            
            let values = snapshot.value as? NSDictionary
            if (values?["schoolCode"] != nil) {
                let schoolCode = values?["schoolCode"] as! String
                self.getClassmates(code: schoolCode)
            }
        }
    }
    
    // Retrieve classmates in the same school
    func getClassmates(code: String) {
        ref.child("schools").child(code).child("students").observe(.value) { (snapshot: DataSnapshot!) in
            
            var tempSchoolmates = [SchoolObject]()
            for item in snapshot.children {
                
                let childSnapshot = snapshot.childSnapshot(forPath: (item as AnyObject).key)
                let values = childSnapshot.value as? NSDictionary
                let name = values?["displayName"] as! String
                let email = values?["email"] as! String
                let photoURL = values?["photoURL"] as! String
                let uid = values?["uid"] as! String
                let url = URL(string: photoURL)
                let data = NSData(contentsOf: url!)
                let image = UIImage(data: data as! Data)!
                if ((uid != Auth.auth().currentUser?.uid)&&(CurrentUser.sharedInstance.convos.contains(uid)) == false) {
                    let add = SchoolObject.init(named: name, emailed: email, photoed: image, uided: uid)
                    tempSchoolmates.append(add)
                }
            }
            
            self.schoolMates = tempSchoolmates
            self.schoolTable.reloadData()
        }
    }
    
    // Dismiss the schoolController when adding is complete
    func initialDismiss() {
        let frame = CGRect(x: self.view.frame.midX - 70, y: self.view.frame.midY - 70, width: 140, height: 140)
        let activity = NVActivityIndicatorView(frame: frame, type: NVActivityIndicatorType(rawValue: 25), color: .blue, padding: nil)
        self.view.addSubview(activity)
        activity.startAnimating()
        let when = DispatchTime.now() + 10
        DispatchQueue.main.asyncAfter(deadline: when) {
            activity.stopAnimating()
        }
        self.delegate.dismiss()
    }
    
    // MARK: TableView methods
    
    func tableView(_ schoolTable: UITableView, numberOfRowsInSection section: Int) -> Int {
            return self.schoolMates.count
    }
    
    func tableView(_ schoolTable: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = schoolTable.dequeueReusableCell(withIdentifier: "schoolCell", for: indexPath) as! SchoolTableViewCell
        cell.schoolImage.layer.masksToBounds = true
        cell.schoolImage.layer.cornerRadius = cell.schoolImage.frame.width/2
        cell.schoolImage.image = schoolMates[indexPath.row].photo
        cell.name.text = schoolMates[indexPath.row].name
        cell.new = schoolMates[indexPath.row].uid
        cell.delegate2 = self
        cell.addingButton.isEnabled = true
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
}

