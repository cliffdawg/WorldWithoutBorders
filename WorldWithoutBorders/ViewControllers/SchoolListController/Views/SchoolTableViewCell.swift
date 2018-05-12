//
//  SchoolTableViewCell.swift
//  WorldWithoutBorders
//
//  Created by Clifford Yin on 3/18/18.
//  Copyright © 2018 Clifford Yin. All rights reserved.
//

import UIKit
import NVActivityIndicatorView

protocol InitialDismissDelegate {
    func initialDismiss()
}

/* Code that constitutes a classmate cell */
class SchoolTableViewCell: UITableViewCell, ResponseDelegate3 {

    @IBOutlet weak var schoolImage: UIImageView!
    @IBOutlet weak var name: UILabel!
    @IBOutlet weak var addingButton: UIButton!
    
    var new = ""
    var delegate2: InitialDismissDelegate!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    // Add the classmate as a conversation
    @IBAction func addConvo(_ sender: Any) {
        let frame = CGRect(x: self.addingButton.frame.midX - 30, y: self.addingButton.frame.midY - 30, width: 60, height: 60)
        let activity = NVActivityIndicatorView(frame: frame, type: NVActivityIndicatorType(rawValue: 32), color: .blue, padding: nil)
        self.addSubview(activity)
        activity.startAnimating()
        self.addingButton.isEnabled = false
        CloudCalls.sharedInstance.runCommand2(action: "addConversation", params: ["recipientUID": new])
        self.delegate2.initialDismiss()
    }
    
    func response3(success: String) {
        
    }
}

