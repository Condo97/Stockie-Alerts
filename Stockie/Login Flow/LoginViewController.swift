//
//  LoginViewController.swift
//  Stockie
//
//  Created by Alex Coundouriotis on 2/25/20.
//  Copyright © 2020 Alex Coundouriotis. All rights reserved.
//

import UIKit

class LoginViewController: UIViewController, UITextFieldDelegate {
    @IBOutlet weak var usernameField: CustomTextField!
    @IBOutlet weak var passwordField: CustomTextField!
    @IBOutlet weak var loginButton: CustomButton!
    @IBOutlet weak var errorMessageLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        usernameField.delegate = self
        passwordField.delegate = self
    }
    
    @IBAction func loginButton(_ sender: Any) {
        if usernameField.text == nil || usernameField.text == "" || passwordField.text == nil || passwordField.text == "" {
            errorMessageLabel.text = "Please make sure all fields are filled."
            return
        }
        
        loginButton.setTitleLater("Logging In...", forControlState: .normal)
        loginButton.isEnabled = false
        
        NetworkHandler.userLogin(usernameField.text!, password: passwordField.text!) {
            tempStockieUserObject, loginError in
            DispatchQueue.main.async {
                if loginError == .Null {
                    self.errorMessageLabel.text = "We're having some difficulty, please try again soon."
                } else if loginError == .InvalidUsername {
                    self.errorMessageLabel.text = "Your Username or Password is Invalid"
                    self.loginButton.isEnabled = true
                } else if loginError == .Success {
                    if let stockieUserObject = tempStockieUserObject {
                        UserDefaults.standard.set(stockieUserObject.username, forKey: "loggedInUser")
                        
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
                            self.errorMessageLabel.text = "Please try again! Error saving Watchlists."
                            print("Error saving Watchlists: \(error)")
                        }
                    }
                } else {
                    self.errorMessageLabel.text = "We have no idea what happened. Please email us!!"
                }
                
                self.loginButton.setTitleLater("Log In", forControlState: .normal)
                self.loginButton.isEnabled = true
            }
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return false
    }
    
    @IBAction func createAccountButton(_ sender: Any) {
        performSegue(withIdentifier: "createAccountSegue", sender: nil)
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
