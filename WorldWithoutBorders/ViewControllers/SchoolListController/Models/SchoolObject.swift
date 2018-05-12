//
//  SchoolObject.swift
//  WorldWithoutBorders
//
//  Created by Clifford Yin on 3/18/18.
//  Copyright © 2018 Clifford Yin. All rights reserved.
//

import Foundation
import UIKit

/* This is the data for a classmate object */
class SchoolObject {
    
    var name: String!
    var email: String!
    var photo: UIImage!
    var uid: String!
    
    init(named: String, emailed: String, photoed: UIImage, uided: String) {
        self.name = named
        self.email = emailed
        self.photo = photoed
        self.uid = uided
    }
    
}
