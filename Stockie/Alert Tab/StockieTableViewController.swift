//
//  StokieTableViewController.swift
//  Stockie
//
//  Created by Alex Coundouriotis on 2/25/20.
//  Copyright © 2020 Alex Coundouriotis. All rights reserved.
//

import UIKit

class StockieTableViewController: UITableViewController, UITextFieldDelegate, AlertTableViewCellDelegate, AdjustTableViewCellDelegate {
    @IBOutlet weak var symbolField: CustomTextField!
    @IBOutlet weak var alertPriceField: CustomTextField!
    @IBOutlet weak var stockNameLabel: UILabel!
    @IBOutlet weak var stockPriceLabel: UILabel!
    @IBOutlet weak var arrowImage: UIImageView!
    @IBOutlet weak var stockChangeLabel: UILabel!
    @IBOutlet weak var stockChangeIntervalLabel: UILabel!
    
    var activeAlerts : [AlertObject] = []
    var inactiveAlerts : [AlertObject] = []
    
    var expandedCell : UITableViewCell = UITableViewCell()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationController!.navigationBar.shadowImage = UIImage()
        navigationController!.navigationBar.layoutIfNeeded()
        navigationController!.navigationBar.tintColor = .white
        navigationController!.navigationBar.isTranslucent = false
        
        symbolField.delegate = self
        alertPriceField.delegate = self
        
        do {
            try CoreDataHandler.getDefaultWatchlist(forUsername: UserDefaults.standard.string(forKey: "loggedInUser")!)
        } catch CoreDataHandlerErrors.invalidDefaultWatchlist {
            do {
                let identityToken = try CoreDataHandler.getIdentityToken(UserDefaults.standard.string(forKey: "loggedInUser")!)
                NetworkHandler.addWatchlist(identityToken, watchlistName: "All Stocks", isDefault: true) {
                    watchlistName, watchlistID, error in
                    
                    if error == NetworkError.Success {
                        do {
                            try CoreDataHandler.save(watchlistObject: WatchlistObject(name: watchlistName, watchlistID: watchlistID, isDefault: true, stocks: []), toUsername: UserDefaults.standard.string(forKey: "loggedInUser")!)
                        } catch { }
                    } else {
                        print("Error adding Default Watchlist: \(error)")
                    }
                }
            } catch { }
        } catch { }
        
        Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) {
            timer in
            
            self.getStocks()
        }
        
        initGetFromCoreData()
        initGetFromNetwork()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        initGetFromNetwork()
    }
    
    func initGetFromCoreData() {
        do {
            let tempAlerts = try CoreDataHandler.getAlerts(forUsername: UserDefaults.standard.string(forKey: "loggedInUser")!)
            
            //(1) Create Temporary Active and Inactive Alert Arrays
            var tempActiveAlerts : [AlertObject] = []
            var tempInactiveAlerts : [AlertObject] = []
            
            for tempAlert in tempAlerts {
                if !tempAlert.hidden {
                    if !tempAlert.executed { tempActiveAlerts.append(tempAlert) }
                    else { tempInactiveAlerts.append(tempAlert) }
                }
            }
            
            //(2) Find difference in count of Temporary and Real Arrays
            let activeAlertRowsToAdd = tempActiveAlerts.count - activeAlerts.count
            let inactiveAlertRowsToAdd = tempInactiveAlerts.count - inactiveAlerts.count
            
            //(2.5) Check if placeholder rows need to be removed
            tableView.beginUpdates()
            
            if activeAlerts.count == 0 && tempActiveAlerts.count != 0 && tableView.numberOfRows(inSection: 0) == 1 { tableView.deleteRows(at: [IndexPath(row: 0, section: 0)], with: .automatic) }
            if inactiveAlerts.count == 0 && tempInactiveAlerts.count != 0 && tableView.numberOfRows(inSection: 1) == 1 { tableView.deleteRows(at: [IndexPath(row: 0, section: 1)], with: .automatic) }
            
            //(3) Delete rows if negative, add rows if positive
            if activeAlertRowsToAdd < 0 {
                var indexPaths : [IndexPath] = []
                for i in 0..<(activeAlertRowsToAdd * -1) { indexPaths.append(IndexPath(row: i, section: 0)) }
                tableView.deleteRows(at: indexPaths, with: .automatic)
            } else if activeAlertRowsToAdd > 0 {
                var indexPaths : [IndexPath] = []
                for i in 0..<activeAlertRowsToAdd { indexPaths.append(IndexPath(row: i, section: 0)) }
                tableView.insertRows(at: indexPaths, with: .automatic)
            }
            
            if inactiveAlertRowsToAdd < 0 {
                var indexPaths : [IndexPath] = []
                for i in 0..<(inactiveAlertRowsToAdd * -1) { indexPaths.append(IndexPath(row: i, section: 1)) }
                tableView.deleteRows(at: indexPaths, with: .automatic)
            } else if inactiveAlertRowsToAdd > 0 {
                var indexPaths : [IndexPath] = []
                for i in 0..<inactiveAlertRowsToAdd { indexPaths.append(IndexPath(row: i, section: 1)) }
                tableView.insertRows(at: indexPaths, with: .automatic)
            }
            
            //(3.5) If no alerts exist, then placeholders must be added
            if activeAlerts.count != 0 && tempActiveAlerts.count == 0 { tableView.insertRows(at: [IndexPath(row: 0, section: 0)], with: .automatic) }
            if inactiveAlerts.count != 0 && tempInactiveAlerts.count == 0 { tableView.insertRows(at: [IndexPath(row: 0, section: 1)], with: .automatic) }
            
            //(4) Set real to temporary :)
            activeAlerts = NSArray(array: tempActiveAlerts) as! [AlertObject]
            inactiveAlerts = NSArray(array: tempInactiveAlerts) as! [AlertObject]
            
            tableView.endUpdates()
            tableView.reloadData()
        } catch CoreDataHandlerErrors.duplicateUser(let userID) {
            print("Duplicate User ID: \(userID)")
            logOut()
        } catch CoreDataHandlerErrors.invalidUser(let userID) {
            print("Invalid User ID: \(userID)")
            logOut()
        } catch {
            print("Unknown error occured during getStockieUserObject(forUserID:)")
            logOut()
        }
    }
    
    func initGetFromNetwork() {
        //TODO: Make sure that the currentStockieUserObject is created with an AuthToken. May require passing the value from the Login or CreateUser views
        do {
            let identityToken = try CoreDataHandler.getIdentityToken(UserDefaults.standard.string(forKey: "loggedInUser")!)
            
            NetworkHandler.getWatchlists(identityToken) {
                watchlistObjects, error in
                
                NetworkHandler.getAlerts(identityToken) {
                    alertObjects, error in
                    if let tempAlerts = alertObjects {
                        let tempStockieUserObject = StockieUserObject(identityToken: identityToken, username: UserDefaults.standard.string(forKey: "loggedInUser")!, watchlists: watchlistObjects, alerts: tempAlerts)
                        do {
                            try CoreDataHandler.update(stockieUser: tempStockieUserObject)
                            
                            DispatchQueue.main.async { self.initGetFromCoreData() }
                        } catch CoreDataHandlerErrors.invalidUser(let userID) {
                            print("Invalid User: \(userID)")
                        } catch CoreDataHandlerErrors.duplicateUser(let userID) {
                            print("Duplicate User: \(userID)")
                        } catch {
                            print("Unknown error occurred during update(stockieUser:): \(error)")
                        }
                    } else {
                        print("Error receiving Alerts from Server.")
                    }
                }
            }
        } catch {
            
        }
        
    }
    
    func getStocks() {
        do {
            let identityToken = try CoreDataHandler.getIdentityToken(UserDefaults.standard.string(forKey: "loggedInUser")!)
            let coreDataStocks = try CoreDataHandler.getAllStocks()
            var stockSymbols : [String] = []
            
            for coreDataStock in coreDataStocks { stockSymbols.append(coreDataStock.symbol) }
            
            NetworkHandler.getStocks(identityToken, stockSymbols) {
                stocks, error in
                
                if error == NetworkError.Success {
                    for stock in stocks ?? [] {
                        do {
                            try CoreDataHandler.update(stockAttributes: stock)
                            
                            DispatchQueue.main.async { self.tableView.reloadData() }
                        } catch {
                            print("Error when updating stock attributes in getStocks(): \(error)")
                        }
                    }
                }
            }
        } catch {
            print("Error occurred during getStocks(): \(error)")
        }
        
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return false
    }
    
    @IBAction func symbolField(_ sender: Any) {
        do {
            let identityToken = try CoreDataHandler.getIdentityToken(UserDefaults.standard.string(forKey: "loggedInUser")!)
            NetworkHandler.getStock(identityToken, stockSymbol: symbolField.text!) {
                stock, error in
                
                DispatchQueue.main.async {
                    if stock == nil {
                        self.stockNameLabel.text = "Invalid Symbol."
                        self.stockPriceLabel.text = ""
                    } else {
                        self.stockNameLabel.text = stock?.company
                        self.stockPriceLabel.text = String(format: "%.2f", stock?.lastPrice ?? 0)
                    }
                }
            }
        } catch {
        
        }
    }
    
    @IBAction func priceField(_ sender: Any) {
    }
    
    @IBAction func addButton(_ sender: Any) {
        if symbolField.text != "" && alertPriceField.text != "" {
            do {
                let identityToken = try CoreDataHandler.getIdentityToken(UserDefaults.standard.string(forKey: "loggedInUser")!)
                
                NetworkHandler.addStockToWatchlist(identityToken, watchlistID: try CoreDataHandler.getDefaultWatchlist(forUsername: UserDefaults.standard.string(forKey: "loggedInUser")!).watchlistID, stockSymbol: symbolField.text!) {
                    error in
                    
                    if error == NetworkError.Success || error == NetworkError.DuplicateIdentifier {
                        DispatchQueue.main.async {
                            NetworkHandler.addAlert(identityToken, stockSymbol: self.symbolField.text!, price: Double(self.alertPriceField.text!)!) {
                                error in
                                
                                if error == .Success {
                                    self.initGetFromNetwork()
                                }
                            }
                        }
                    } else {
                        print("Error adding Stock to Watchlist: \(error)")
                    }
                }
                
            } catch {
                print("Error getting IdentityToken or DefaultWatchlist in AddButton(): \(error)")
            }
        }
    }
    
    @IBAction func addToWatchlistButton(_ sender: Any) {
        if symbolField.text != "" && alertPriceField.text != "" {
            performSegue(withIdentifier: "toSelectWatchlist", sender: nil)
        }
    }
    
    func didPressArrowButton(sender: Any) {
    }
    
    func didPressCheckButton(sender: Any) {
    }
    
    func didPressCancelButton(sender: Any) {
    }
    
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        var count = 0
        
        if expandedCell is AlertTableViewCell {
            count += 1
        }
        
        if section == 0 && activeAlerts.count == 0 { return count + 1 }
        if section == 1 && inactiveAlerts.count == 0 { return 1 }
        
        if section == 0 { return count + activeAlerts.count }
        return count + inactiveAlerts.count
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 { return "Active Alerts" }
        
        return "Past Alerts"
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if expandedCell is AlertTableViewCell && indexPath.row - 1 == (tableView.indexPath(for: expandedCell) ?? IndexPath()).row {
            let cell = tableView.dequeueReusableCell(withIdentifier: "adjustCell") as! AdjustTableViewCell
            cell.cellDelegate = self
            return cell
        }
        
        
        if indexPath.section == 0 && activeAlerts.count == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "noAlertCell", for: indexPath) as! NoAlertTableViewCell
            cell.centerLabel.text = "No Active Alerts"
            
            return cell
            
        } else if indexPath.section == 1 && inactiveAlerts.count == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "noAlertCell", for: indexPath) as! NoAlertTableViewCell
            cell.centerLabel.text = "No Past Alerts"
            
            return cell
        }
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "alertCell", for: indexPath) as! AlertTableViewCell
        let currentAlert : AlertObject
        
        cell.cellDelegate = self
        
        if indexPath.section == 0 {
            currentAlert = activeAlerts[indexPath.row]
        } else {
            currentAlert = inactiveAlerts[indexPath.row]
            cell.bellImageView.image = nil

        }
        
        do {
            cell.currentPrice.text = "\(try CoreDataHandler.getStock(forSymbol: currentAlert.symbol).lastPrice)"
        } catch {
            cell.currentPrice.text = "Error Fetching Price."
        }
        
        cell.alertPrice.text = String(format: "%.2f", currentAlert.price)
        cell.symbol.text = "\(currentAlert.symbol)"
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if tableView.cellForRow(at: indexPath) == expandedCell {
            expandedCell = UITableViewCell()
            
            tableView.deleteRows(at: [IndexPath(row: indexPath.row + 1, section: indexPath.section)], with: .automatic)
        } else if let tempCell = tableView.cellForRow(at: indexPath) as? AlertTableViewCell {
            expandedCell = tempCell
            
            tableView.insertRows(at: [IndexPath(row: indexPath.row + 1, section: indexPath.section)], with: .automatic)
        }
        
        tableView.beginUpdates()
        tableView.endUpdates()
        
        tableView.cellForRow(at: indexPath)!.isSelected = false
    }
    
//    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
//        if let tempCell = expandedCell as? AlertTableViewCell {
//            
//        }
//    }
    
    
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    
    
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    
    
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {
        
    }
    
    
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toSelectWatchlist" {
            if let navController = segue.destination as? UINavigationController {
                if let swtvc = navController.topViewController as? SelectWatchlistTableViewController {
                    swtvc.symbol = symbolField.text!
                    swtvc.price = Double(alertPriceField.text!)!
                }
            }
        }
    }
    
    func logOut() {
        UserDefaults.standard.removeObject(forKey: "loggedInUser")
        performSegue(withIdentifier: "logOutSegue", sender: nil)
    }
}
