//
//  WatchlistTableViewCell.swift
//  Stockie
//
//  Created by Alex Coundouriotis on 3/16/20.
//  Copyright © 2020 Alex Coundouriotis. All rights reserved.
//

import UIKit

class WatchlistTableViewCell: UITableViewCell {
    @IBOutlet weak var symbolLabel: UILabel!
    @IBOutlet weak var priceLabel: UILabel!
    @IBOutlet weak var upByPriceLabel: UILabel!
    @IBOutlet weak var priceDirectionImageView: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
