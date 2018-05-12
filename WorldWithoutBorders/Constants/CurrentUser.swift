//
//  CurrentUser.swift
//  WorldWithoutBorders
//
//  Created by Clifford Yin on 2/9/18.
//  Copyright © 2018 Clifford Yin. All rights reserved.
//

import Foundation
import Firebase
import GoogleSignIn

/* Code that constitutes the data for the current user, both Google and Firebase */
class CurrentUser {
    
    static let sharedInstance = CurrentUser()
    
    fileprivate init () {
        
    }
    
    var user: GIDGoogleUser!
    var unwrapImage: UIImage!
    var urled: String!
    var convos = [String]()
    
    func instantiate(_ signIn: GIDGoogleUser) {
        self.user = signIn
        let imageUrl = user.profile.imageURL(withDimension: 150)
        let data = NSData(contentsOf: imageUrl!)
        self.unwrapImage = UIImage(data: data as! Data)
        self.urled = imageUrl?.absoluteString
    }
}
