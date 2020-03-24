//
//  AlertTableViewCell.swift
//  Stockie
//
//  Created by Alex Coundouriotis on 2/24/20.
//  Copyright © 2020 Alex Coundouriotis. All rights reserved.
//

import UIKit

protocol AlertTableViewCellDelegate {
    func didPressArrowButton(sender: Any)
}

class AlertTableViewCell: UITableViewCell {
    @IBOutlet weak var symbol: UILabel!
    @IBOutlet weak var currentPrice: UILabel!
    @IBOutlet weak var stockImageView: UIImageView!
    @IBOutlet weak var alertPrice: UILabel!
    @IBOutlet weak var bellImageView: UIImageView!
    @IBOutlet weak var arrowImageView: UIImageView!
    @IBOutlet weak var arrowButton: UIButton!
    
    var cellDelegate : AlertTableViewCellDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    @IBAction func arrowButton(_ sender: Any) {
        cellDelegate?.didPressArrowButton(sender: sender)
    }
}
