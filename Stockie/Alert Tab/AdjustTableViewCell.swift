//
//  AdjustTableViewCell.swift
//  Stockie
//
//  Created by Alex Coundouriotis on 3/10/20.
//  Copyright © 2020 Alex Coundouriotis. All rights reserved.
//

import UIKit

protocol AdjustTableViewCellDelegate {
    func didPressCheckButton(sender: Any)
    func didPressCancelButton(sender: Any)
}

class AdjustTableViewCell: UITableViewCell {
    @IBOutlet weak var priceField: CustomTextField!
    
    var cellDelegate : AdjustTableViewCellDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    @IBAction func checkButton(_ sender: Any) {
        cellDelegate?.didPressCheckButton(sender: sender)
    }
    
    @IBAction func cancelButton(_ sender: Any) {
        cellDelegate?.didPressCancelButton(sender: sender)
    }
}
