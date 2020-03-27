//
//  SelectWatchlistTableViewController.swift
//  Stockie
//
//  Created by Alex Coundouriotis on 3/10/20.
//  Copyright © 2020 Alex Coundouriotis. All rights reserved.
//

import UIKit

class SelectWatchlistTableViewController: UITableViewController {
    var symbol : String = ""
    var price : Double = 0
    
    var watchlists : [WatchlistObject] = []
    
    var saveWatchlistAction : UIAlertAction = UIAlertAction()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        getWatchlists()
    }
    
    func getWatchlists() {
        do {
            watchlists = try CoreDataHandler.getWatchlists(forUsername: UserDefaults.standard.string(forKey: "loggedInUser")!)
        } catch {
            let alert = UIAlertController(title: "Something Happened...", message: "We apologize, for some reason we can't access your watchlists. Please try again soon.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Done", style: .default) {
                action in
                self.dismiss(animated: true, completion: nil)
            })
            
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    @IBAction func cancel(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 2
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        if section == 1 { return 1 }
        return watchlists.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 1 { return tableView.dequeueReusableCell(withIdentifier: "addWatchlistCell")! }
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        
        cell.textLabel!.text = watchlists[indexPath.row].name
        cell.detailTextLabel!.text = "\(watchlists[indexPath.row].stocks.count) Stocks"
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if indexPath.section == 1 { addWatchlist() }
        else {
            do {
                let identityToken = try CoreDataHandler.getIdentityToken(UserDefaults.standard.string(forKey: "loggedInUser")!)
                
                NetworkHandler.addStockToWatchlist(identityToken, watchlistID: watchlists[indexPath.row].watchlistID, stockSymbol: symbol) {
                    error in
                    
                    if error == NetworkError.Success {
                        NetworkHandler.addStockToWatchlist(identityToken, watchlistID: self.watchlists[0].watchlistID, stockSymbol: self.symbol) {
                            error in
                            
                            DispatchQueue.main.async {
                                if error == NetworkError.Success || error == NetworkError.DuplicateIdentifier {
                                    NetworkHandler.addAlert(identityToken, stockSymbol: self.symbol, price: self.price) {
                                        error in
                                        DispatchQueue.main.async {
                                            if error == NetworkError.Success {
                                                self.dismiss(animated: true, completion: nil)
                                            } else if error == NetworkError.ExpiredIdentity {
                                                self.dismiss(animated: true, completion: nil)
                                            } else {
                                                let alert = UIAlertController(title: "Something Happened...", message: "We apologize, for some reason we can't add the new Alert. Please try again soon.", preferredStyle: .alert)
                                                alert.addAction(UIAlertAction(title: "Done", style: .default) {
                                                    action in
                                                    self.dismiss(animated: true, completion: nil)
                                                })
                                                
                                                self.present(alert, animated: true, completion: nil)
                                            }
                                        }
                                    }
                                } else if error == NetworkError.ExpiredIdentity {
                                    self.dismiss(animated: true, completion: nil)
                                } else {
                                    let alert = UIAlertController(title: "Something Happened...", message: "We apologize, for some reason we can't add the Stock to your Watchlist. Please try again soon.", preferredStyle: .alert)
                                    alert.addAction(UIAlertAction(title: "Done", style: .default) {
                                        action in
                                        self.dismiss(animated: true, completion: nil)
                                    })
                                    
                                    self.present(alert, animated: true, completion: nil)
                                }
                            }
                        }
                    }
                }
            } catch {
                let alert = UIAlertController(title: "Something Happened...", message: "We apologize, for some reason we couldn't read your Watchlists. Please try again soon.", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Done", style: .default) {
                    action in
                    self.dismiss(animated: true, completion: nil)
                })
                
                self.present(alert, animated: true, completion: nil)
            }
        }
    }
    
    func addWatchlist() {
        do {
            let identityToken = try CoreDataHandler.getIdentityToken(UserDefaults.standard.string(forKey: "loggedInUser")!)
            let alertController = UIAlertController(title: "New Watchlist", message: "Please name your watchlist.", preferredStyle: .alert)
            alertController.addTextField() {
                textField in
                textField.placeholder = "Watchlist Name..."
                textField.addTarget(self, action: #selector(self.addWatchlistTextDidChange(_:)), for: .editingChanged)
            }
            
            saveWatchlistAction = UIAlertAction(title: "Done", style: .default) {
                action in
                let watchlistNameTextField = alertController.textFields![0]
                
                NetworkHandler.addWatchlist(identityToken, watchlistName: watchlistNameTextField.text!, isDefault: false) {
                    watchlistName, watchlistID, error in
                    
                    if error == NetworkError.Success {
                        do {
                            try CoreDataHandler.save(watchlistObject: WatchlistObject(name: watchlistName, watchlistID: watchlistID, isDefault: false, stocks: []), toUsername: UserDefaults.standard.string(forKey: "loggedInUser")!)
                            
                            self.getWatchlists()
                            
                            DispatchQueue.main.async { self.tableView.insertRows(at: [IndexPath(row: self.tableView.numberOfRows(inSection: 0), section: 0)], with: .automatic) }
                        } catch { }
                    } else {
                        print("Error adding Watchlist to User in SelectWatchlistTableViewController: \(error)")
                    }
                }
            }
            
            saveWatchlistAction.isEnabled = false
            alertController.addAction(saveWatchlistAction)
            
            alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            
            present(alertController, animated: true, completion: nil)
        } catch {
            print("Unable to add Watchlist in SelectWatchlistTableViewController: \(error)")
        }
    }
    
    @objc func addWatchlistTextDidChange(_ textField: UITextField) {
        if let textFieldText = textField.text {
            if textFieldText.count == 0 {
                saveWatchlistAction.isEnabled = false
            } else {
                saveWatchlistAction.isEnabled = true
            }
        }
    }
}
