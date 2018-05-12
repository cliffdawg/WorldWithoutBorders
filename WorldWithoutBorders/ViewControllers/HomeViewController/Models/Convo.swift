//
//  Convo.swift
//  WorldWithoutBorders
//
//  Created by Clifford Yin on 2/10/18.
//  Copyright © 2018 Clifford Yin. All rights reserved.
//

import Foundation
import UIKit
import Firebase

/* Code that constitutes a current conversation of the user */
class Convo {
    
    let ref = Database.database().reference()
    var image: UIImage!
    var name: String!
    var unreadMessages: Int!
    var uid: String!
    
    init(userImage: UIImage, named: String, unread: Int, id: String) {
        self.image = userImage
        self.name = named
        self.unreadMessages = unread
        self.uid = id
    }
    
}
