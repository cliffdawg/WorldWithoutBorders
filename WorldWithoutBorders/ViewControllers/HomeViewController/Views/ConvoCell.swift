//
//  AvailableConvoCell.swift
//  WorldWithoutBorders
//
//  Created by Clifford Yin on 2/9/18.
//  Copyright © 2018 Clifford Yin. All rights reserved.
//

import UIKit

/* Cell that displays a current conversation of the user */
class ConvoCell: UITableViewCell {

    @IBOutlet weak var profilePic: UIImageView!
    @IBOutlet weak var name: UILabel!
    @IBOutlet weak var unreadCount: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
}
