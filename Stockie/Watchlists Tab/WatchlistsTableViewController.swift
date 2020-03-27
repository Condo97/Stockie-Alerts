//
//  WatchlistsTableViewController.swift
//  Stockie
//
//  Created by Alex Coundouriotis on 3/16/20.
//  Copyright © 2020 Alex Coundouriotis. All rights reserved.
//

import UIKit

class WatchlistsTableViewController: UITableViewController {
    
    var watchlists : [WatchlistObject] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) {
            timer in
            self.initGetFromNetwork()
        }
        
        initGetFromCoreData()
        initGetFromNetwork()
    }
    
    func initGetFromCoreData() {
        do {
            tableView.beginUpdates()
            
            let tempWatchlists = try CoreDataHandler.getWatchlists(forUsername: UserDefaults.standard.string(forKey: "loggedInUser")!)
            
            if tempWatchlists.count > watchlists.count {
                for i in watchlists.count..<tempWatchlists.count {
                    tableView.insertSections(IndexSet(integer: i), with: .automatic)
                }
            } else if watchlists.count > tempWatchlists.count {
                for i in (watchlists.count - 1)...tempWatchlists.count {
                    tableView.deleteSections(IndexSet(integer: i), with: .automatic)
                }
            }
            
            for i in 0..<tempWatchlists.count {
                let tempWatchlist = tempWatchlists[i]
                
                if i >= watchlists.count {
                    for j in 0..<tempWatchlist.stocks.count {
                        tableView.insertRows(at: [IndexPath(row: j, section: i)], with: .automatic)
                    }
                } else {
                    let watchlist = watchlists[i]
                    
                    if tempWatchlist.stocks.count > watchlist.stocks.count {
                        for j in watchlist.stocks.count..<tempWatchlist.stocks.count {
                            tableView.insertRows(at: [IndexPath(row: j, section: i)], with: .automatic)
                        }
                    } else if watchlist.stocks.count > tempWatchlist.stocks.count {
                        for j in (watchlist.stocks.count - 1)...tempWatchlist.stocks.count {
                            tableView.deleteRows(at: [IndexPath(row: j, section: i)], with: .automatic)
                        }
                    }
                }
            }
            
//            var additionalSections = 0
//            for tempWatchlist in tempWatchlists {
//                if !watchlists.contains(tempWatchlist) {
//                    additionalSections += 1
//                    watchlists.append(tempWatchlist)
//                }
//            }
//
//            for i in 0..<watchlists.count {
//                let watchlist = watchlists[i]
//                if !tempWatchlists.contains(watchlist) {
//                    additionalSections -= 1
//                                          watchlists.remove(at: i)
//                }
//            }
            
//            var additional : [Int] = []
//            for i in 0..<watchlists.count {
//                let watchlist = watchlists[i]
//                var additionalRows = 0
//
//                var found = false
//                for j in 0..<tempWatchlists.count {
//                    let tempWatchlist = tempWatchlists[j]
//
//                    if watchlist.watchlistID == tempWatchlist.watchlistID {
//                        //If Stock count of watchlist is > Stock count of tempWatchlist, that means stocks have been deleted from CoreData. Decrement rows in section.
//                        if watchlist.stocks.count > tempWatchlist.stocks.count { additionalRows -= 1 }
//
//                        //If Stock count of tempWatchlist is > Stock count of Watchlist, that means stocks have been added to CoreData. Increment rows in section.
//                        else if watchlist.stocks.count < tempWatchlist.stocks.count { additionalRows += 1 }
//
//                        found = true
//                    }
//                }
//
//                if found {
//                    additional.append(additionalRows)
//                }
//            }
            
            self.watchlists = tempWatchlists
//
//            if tempWatchlists.count > watchlists.count {
//                for i in 0..<(tempWatchlists.count - watchlists.count) {
//                    tableView.insertSections(IndexSet(integer: i), with: .automatic)
//                }
//            } else if tempWatchlists.count < watchlists.count {
//                for i in 0..<(watchlists.count - tempWatchlists.count) {
//                    tableView.deleteSections(IndexSet(integer: i), with: .automatic)
//                }
//            }
//
//            var index = 0
//            for _ in 0..<watchlists.count {
//                let watchlist = watchlists[index]
//
//                var found = false
//                for i in 0..<tempWatchlists.count {
//                    if watchlist.watchlistID == tempWatchlists[i].watchlistID { found = true }
//                }
//
//                tableView.deleteRows(at: [IndexPath(row: index, section: index)], with: .automatic)
//                watchlists.remove(at: watchlists.firstIndex(of: watchlist)!)
//            }
//
//
//            index = 0
//            for i in 0..<tempWatchlists.count {
//                let tempWatchlist = tempWatchlists[i]
//                if !watchlists.contains(tempWatchlist) {
//                    tableView.insertRows(at: [IndexPath(row: index, section: i)], with: .automatic)
//                    watchlists.append(tempWatchlist)
//                } else { index += 1 }
//            }
            
            
            
            tableView.endUpdates()
            tableView.reloadData()
        } catch {
            logOut()
        }
    }
    
    func initGetFromNetwork() {
        do {
            let identityToken = try CoreDataHandler.getIdentityToken(UserDefaults.standard.string(forKey: "loggedInUser")!)
            
            NetworkHandler.getWatchlists(identityToken) {
                watchlistObjects, error in
                
                if error == NetworkError.Success {
                    do {
                        for watchlist in watchlistObjects { try CoreDataHandler.update(watchlist: watchlist, forUsername: UserDefaults.standard.string(forKey: "loggedInUser")!) }
                        
                        DispatchQueue.main.async { self.initGetFromCoreData() }
                    } catch {
                        print("Unknown error occurred during update(watchlists:): \(error)")
                    }
                }
            }
        } catch {
            print("Unknown error occurred during getidentityToken(): \(error)")
        }
    }
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return watchlists.count
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return watchlists[section].name
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return watchlists[section].stocks.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "watchlistCell") as! WatchlistTableViewCell
        
        cell.symbolLabel.text = watchlists[indexPath.section].stocks[indexPath.row].symbol
        cell.priceLabel.text = "$\( watchlists[indexPath.section].stocks[indexPath.row].lastPrice)"
        
        return cell
    }
    
    func logOut() {
        UserDefaults.standard.removeObject(forKey: "loggedInUser")
        performSegue(withIdentifier: "logOutSegue", sender: nil)
    }

}
