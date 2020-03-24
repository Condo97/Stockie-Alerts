//
//  CustomTextField.swift
//  Stockie
//
//  Created by Alex Coundouriotis on 2/27/20.
//  Copyright © 2020 Alex Coundouriotis. All rights reserved.
//

import UIKit

class CustomTextField: UITextField {
    
    @IBInspectable var shadowColor : UIColor? = nil
    @IBInspectable var shadowRadius : CGFloat = 0.0
    @IBInspectable var shadowOffset : CGSize = CGSize()
    @IBInspectable var shadowOpacity : CGFloat = 0.0
    
    @IBInspectable var cornerRadius : CGFloat = 0.0
    @IBInspectable var theBackgroundColor : UIColor? = nil
    @IBInspectable var image : UIImage? = nil
    
    @IBInspectable var useBorder : Bool = false
    @IBInspectable var borderWidth : CGFloat = 0.0
    @IBInspectable var borderColor : UIColor? = nil
    
    @IBInspectable var indentPixels : CGFloat = 0.0
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        clipsToBounds = false
        backgroundColor = theBackgroundColor
        layer.cornerRadius = cornerRadius
        layer.masksToBounds = true
        
        if useBorder {
            layer.borderColor = borderColor?.cgColor
            layer.borderWidth = borderWidth
        }
        
        if self.image != nil {
            let imageView = UIImageView(image: image)
            imageView.frame = bounds
            addSubview(imageView)
            sendSubviewToBack(imageView)
        }
        
        leftView = UIView(frame: CGRect(x: 0, y: 0, width: indentPixels, height: 0))
        leftViewMode = .always
    }
    
    func setTheBorderColorLater(_ theBorderColor: UIColor) {
        layer.borderColor = theBorderColor.cgColor
    }
}
