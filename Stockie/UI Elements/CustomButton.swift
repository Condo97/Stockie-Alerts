//
//  CustomButton.swift
//  Stockie
//
//  Created by Alex Coundouriotis on 2/26/20.
//  Copyright © 2020 Alex Coundouriotis. All rights reserved.
//

import UIKit

class CustomButton: UIButton {
    @IBInspectable var shadowColor : UIColor? = nil
    @IBInspectable var shadowRadius : CGFloat = 0.0
    @IBInspectable var shadowOffset : CGSize = CGSize()
    @IBInspectable var shadowOpacity : CGFloat = 0.0
    
    @IBInspectable var cornerRadius : CGFloat = 0.0
    @IBInspectable var theBackgroundColor : UIColor? = nil
    @IBInspectable var image: UIImage? = nil
    
    @IBInspectable var useBorder : Bool = false
    @IBInspectable var theBorderWidth : CGFloat = 0.0
    @IBInspectable var theBorderColor : UIColor? = nil
    
    var roundedView = UIButton()
    var tap = UITapGestureRecognizer()
    
    
    override func awakeFromNib() {
        layer.shadowColor = shadowColor?.cgColor
        layer.shadowRadius = shadowRadius
        layer.shadowOffset = shadowOffset
        layer.shadowOpacity = Float(shadowOpacity / 100.0)
        clipsToBounds = false
        
        roundedView = UIButton(type: .system)
        roundedView.frame = self.bounds
        roundedView.addTarget(self, action: #selector(handleTap(_:)), for: .touchUpInside)
        roundedView.backgroundColor = theBackgroundColor
        roundedView.layer.masksToBounds = true
        roundedView.setTitle(currentTitle, for: .normal)
        roundedView.titleLabel?.font = titleLabel?.font
        roundedView.setTitleColor(tintColor, for: .normal)
        roundedView.layer.cornerRadius = cornerRadius
        setTitle("", for: .normal)
        
        if useBorder {
            roundedView.layer.borderColor = theBorderColor?.cgColor
            roundedView.layer.borderWidth = theBorderWidth
        }
        
        addSubview(roundedView)
        
        if image != nil {
            let theImageView = UIImageView(image: image)
            theImageView.frame = bounds
            addSubview(theImageView)
            sendSubviewToBack(theImageView)
        }
        
        sendSubviewToBack(roundedView)
    }
    
    @objc func handleTap(_ button: UIButton) {
        sendActions(for: .touchUpInside)
    }
    
    func setTheBorderColorLater(_ theBorderColor: UIColor) {
        roundedView.layer.borderColor = theBorderColor.cgColor
    }
    
    func setTitleColorLater(_ titleColor: UIColor, forControlState controlState: UIControl.State) {
        roundedView .setTitleColor(titleColor, for: controlState)
    }
    
    func setTitleLater(_ title: String, forControlState controlState: UIControl.State) {
        roundedView.setTitle(title, for: controlState)
    }
}
