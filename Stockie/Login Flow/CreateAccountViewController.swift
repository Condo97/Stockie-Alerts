//
//  CreateAccountViewController.swift
//  Stockie
//
//  Created by Alex Coundouriotis on 2/26/20.
//  Copyright © 2020 Alex Coundouriotis. All rights reserved.
//

import UIKit

class CreateAccountViewController: UIViewController, UITextFieldDelegate {
    @IBOutlet weak var errorLabel: UILabel!
    @IBOutlet weak var usernameField: CustomTextField!
    @IBOutlet weak var passwordField: CustomTextField!
    @IBOutlet weak var confirmPasswordField: CustomTextField!
    @IBOutlet weak var createAccount: CustomButton!
    @IBOutlet weak var circleImage: UIImageView!
    @IBOutlet weak var circleActivity: UIActivityIndicatorView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        usernameField.delegate = self
        passwordField.delegate = self
        confirmPasswordField.delegate = self
    }
    
    @IBAction func createAccount(_ sender: Any) {
        if passwordField.text != confirmPasswordField.text {
            errorLabel.text = "Passwords do not match."
            return
        }
        
        if usernameField.text == nil || usernameField.text == "" || passwordField.text == nil || passwordField.text == "" || confirmPasswordField.text == nil || confirmPasswordField.text == "" {
            errorLabel.text = "Please make sure all fields are filled."
            return
        }
        
        createAccount.setTitleLater("Creating Account...", forControlState: .normal)
        
        NetworkHandler.addUser(usernameField.text!, password: passwordField.text!) {
            tempStockieUserObject, error in
            DispatchQueue.main.async {
                self.createAccount.setTitleLater("Create Account", forControlState: .normal)
                
                if error == .Null {
                    self.errorLabel.text = "We're having some difficulty, please try again soon."
                } else if error == .DuplicateObject {
                    self.errorLabel.text = "Username exists. Please try another."
                } else if error == .Success {
                    if var stockieUserObject = tempStockieUserObject {
                        UserDefaults.standard.set(stockieUserObject.username, forKey: "loggedInUser")
                        
                        NetworkHandler.getWatchlists(stockieUserObject.identityToken) {
                            watchlistObjects, watchlistError in
                            if watchlistError == .Success {
                                stockieUserObject.watchlists = watchlistObjects ?? []
                                
                                do {
                                    try CoreDataHandler.save(stockieUserObject: stockieUserObject)
                                    
                                    DispatchQueue.main.async {
                                        self.performSegue(withIdentifier: "logInSegue", sender: nil)
                                    }
                                } catch CoreDataHandlerErrors.duplicateUser(_) {
                                    do {
                                        try CoreDataHandler.update(stockieUser: stockieUserObject)
                                        
                                        DispatchQueue.main.async {
                                            self.performSegue(withIdentifier: "logInSegue", sender: nil)
                                        }
                                    } catch {
                                        print("Error updating User: \(error)")
                                    }
                                } catch {
                                    self.errorLabel.text = "Please try again! Error saving Watchlists."
                                    print("Error saving User: \(error)")
                                }
                            } else {
                                self.errorLabel.text = "Please try again! Error getting watchilsts."
                            }
                        }
                    }
                } else {
                    self.errorLabel.text = "We have no idea what happened. Please email us!!"
                }
            }
        }
    }
    
    func showActivity() {
        circleActivity.startAnimating()
        circleActivity.alpha = 0.0
        UIView.animate(withDuration: 0.2) {
            self.circleActivity.alpha = 1.0
        }
    }
    
    func hideActivity() {
        circleActivity.alpha = 1.0
        UIView.animate(withDuration: 0.2, animations: {
            self.circleActivity.alpha = 0.0
        }) {
            someValue in
            self.circleActivity.stopAnimating()
        }
    }
    
    @IBAction func close(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func beganEditingUsername(_ sender: Any) {
        UIView.animate(withDuration: 0.3) {
            self.circleImage.tintColor = UIColor(named: "StockieGreen")
            self.circleImage.image = UIImage(systemName: "circle")
        }
        
        showActivity()
    }
    
    @IBAction func finishedEditingUsername(_ sender: Any) {
        if(usernameField.text != nil && usernameField.text != "") {
            NetworkHandler.checkUser(usernameField.text!) {
                error in
                DispatchQueue.main.async {
                    self.hideActivity()
                    
                    if error == .DuplicateObject {
                        UIView.animate(withDuration: 0.3) {
                            self.circleImage.tintColor = UIColor(named: "StockieRed")
                            self.circleImage.image = UIImage(systemName: "xmark.circle")
                        }
                    } else if error == .Success {
                        UIView.animate(withDuration: 0.3) {
                            self.circleImage.tintColor = UIColor(named: "StockieGreen")
                            self.circleImage.image = UIImage(systemName: "checkmark.circle")
                        }
                    }
                }
            }
        } else {
            hideActivity()
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return false
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
