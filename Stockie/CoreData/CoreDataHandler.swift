//
//  CoreDataHandler.swift
//  Stockie
//
//  Created by Alex Coundouriotis on 2/25/20.
//  Copyright © 2020 Alex Coundouriotis. All rights reserved.
//

import UIKit
import CoreData

class CoreDataHandler: NSObject {
    static let staticManagedContext = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    
    
    // MARK: - Saving to Core Data
    
    static func save(stockieUserObject: StockieUserObject) throws {
        let managedContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        managedContext.parent = staticManagedContext
        
        do {
            _ = try getStockieUserObject(forUsername: stockieUserObject.username)
        } catch CoreDataHandlerErrors.invalidUser {
            let entity = NSEntityDescription.entity(forEntityName: "StockieUser", in: managedContext)!
            let user = NSManagedObject(entity: entity, insertInto: managedContext)
            
            for watchlistObject in stockieUserObject.watchlists {
                try save(watchlistObject: watchlistObject, toUsername: stockieUserObject.username)
            }
            
            user.setValue(stockieUserObject.identityToken, forKeyPath: "identityToken")
            user.setValue(stockieUserObject.username, forKeyPath: "username")
            
            try managedContext.save()
            
            asyncSave()
        }
    }
    
    static func save(watchlistObject: WatchlistObject, toUsername username: String) throws {
        let managedContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        managedContext.parent = staticManagedContext
        
        do {
            _ = try getWatchlist(forWatchlistID: watchlistObject.watchlistID, andUsername: username)
        } catch CoreDataHandlerErrors.invalidWatchlist(_) {
            //NOTE: Invalid Stock indicates the stock does not exist.
            
            for stock in watchlistObject.stocks {
                do {
                    try save(stockObject: stock, toWatchlistObject: watchlistObject)
                } catch { }
            }
            
            let entity = NSEntityDescription.entity(forEntityName: "Watchlist", in: managedContext)!
            let watchlist = NSManagedObject(entity: entity, insertInto: managedContext)
            
            watchlist.setValue(username, forKey: "username")
            watchlist.setValue(watchlistObject.name, forKey: "name")
            watchlist.setValue(watchlistObject.isDefault, forKey: "isDefault")
            watchlist.setValue(watchlistObject.watchlistID, forKey: "watchlistID")
            
            try managedContext.save()
            
            asyncSave()
        }
    }
    
    static func save(stockObject: StockObject, toWatchlistObject watchlistObject: WatchlistObject) throws {
        let managedContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        managedContext.parent = staticManagedContext
        
        if try watchlistStockAssociationExists(forWatchlistID: watchlistObject.watchlistID, andSymbol: stockObject.symbol) {
            throw CoreDataHandlerErrors.duplicateWatchlistStockAssociations(watchlistID: watchlistObject.watchlistID, symbol: stockObject.symbol)
        }
        
        if try stockExists(symbol: stockObject.symbol) {
            try update(stockAttributes: stockObject)
        } else {
            try save(stockObject: stockObject)
        }
        
        let entity = NSEntityDescription.entity(forEntityName: "WatchlistStock", in: managedContext)!
        let watchlistStock = NSManagedObject(entity: entity, insertInto: managedContext)
        
        watchlistStock.setValue(watchlistObject.watchlistID, forKey: "watchlistID")
        watchlistStock.setValue(stockObject.symbol, forKey: "symbol")
        
        try managedContext.save()
        
        asyncSave()
    }
    
    static func save(stockObject: StockObject) throws {
        let managedContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        managedContext.parent = staticManagedContext
        
        do {
            _ = try getStock(forSymbol: stockObject.symbol)
        } catch CoreDataHandlerErrors.invalidStock {
            let entity = NSEntityDescription.entity(forEntityName: "Stock", in: managedContext)!
            let stock = NSManagedObject(entity: entity, insertInto: managedContext)
            
            stock.setValue(stockObject.company, forKey: "company")
            stock.setValue(stockObject.symbol, forKey: "symbol")
            stock.setValue(stockObject.lastPrice, forKey: "lastPrice")
            
            try managedContext.save()
            
            asyncSave()
        }
    }
    
    static func save(alertObject: AlertObject, toUsername username: String) throws {
        let managedContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        managedContext.parent = staticManagedContext
        
        do {
            _ = try getAlert(forAlertID: alertObject.alertID)
        } catch CoreDataHandlerErrors.invalidAlert {
            let entity = NSEntityDescription.entity(forEntityName: "Alert", in: managedContext)!
            let alert = NSManagedObject(entity: entity, insertInto: managedContext)
            
            alert.setValue(alertObject.alertID, forKey: "alertID")
            alert.setValue(username, forKey: "username")
            alert.setValue(alertObject.symbol, forKey: "symbol")
            alert.setValue(alertObject.price, forKey: "price")
            alert.setValue(alertObject.overPrice, forKey: "overPrice")
            alert.setValue(alertObject.executed, forKey: "executed")
            alert.setValue(alertObject.hidden, forKey: "hidden")
            
            try managedContext.save()
            
            asyncSave()
        }
    }
    
    
    //MARK: - Updating Core Data
    
    /**
     * Updates the StockieUser Object in CoreData
     *
     * Actions:
     *      INSERTS into CoreData if Object is not in CoreData
     *      UPDATES CoreData object if Object is in CoreData
     *      REMOVES CoreData object if CoreData returns an Object not in the StockieUserObject
     */
    static func update(stockieUser stockieUserObject: StockieUserObject) throws {
        let managedContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        managedContext.parent = staticManagedContext
        
        let cdStockieUserObject = try getStockieUserObject(forUsername: stockieUserObject.username)
        
        //Update Watchlists
        var watchlistsToDelete : [WatchlistObject] = NSArray(array: cdStockieUserObject.watchlists) as! [WatchlistObject]
        var watchlistsToAppend : [WatchlistObject] = NSArray(array: stockieUserObject.watchlists) as! [WatchlistObject]
        var watchlistsToUpdate : [WatchlistObject] = []
        
        for i in 0..<cdStockieUserObject.watchlists.count {
            for j in 0..<stockieUserObject.watchlists.count {
                if cdStockieUserObject.watchlists[i].watchlistID == stockieUserObject.watchlists[j].watchlistID {
                    watchlistsToDelete.remove(at: watchlistsToDelete.lastIndex(of: cdStockieUserObject.watchlists[i])!)
                    watchlistsToAppend.remove(at: watchlistsToAppend.lastIndex(of: stockieUserObject.watchlists[j])!)
                    watchlistsToUpdate.append(stockieUserObject.watchlists[j])
                }
            }
        }
        
        for watchlistToDelete in watchlistsToDelete { try remove(watchlistByID: watchlistToDelete.watchlistID) }
        for watchlistToAppend in watchlistsToAppend { try save(watchlistObject: watchlistToAppend, toUsername: stockieUserObject.username) }
        for watchlistToUpdate in watchlistsToUpdate { try update(watchlist: watchlistToUpdate, forUsername: cdStockieUserObject.username) }
        
        
        //Update Alerts
        var alertsToDelete : [AlertObject] = NSArray(array: cdStockieUserObject.alerts) as! [AlertObject]
        var alertsToAppend : [AlertObject] = NSArray(array: stockieUserObject.alerts) as! [AlertObject]
        var alertsToUpdate : [AlertObject] = []
        
        for i in 0..<cdStockieUserObject.alerts.count {
            for j in 0..<stockieUserObject.alerts.count {
                if cdStockieUserObject.alerts[i].alertID == stockieUserObject.alerts[j].alertID {
                    alertsToDelete.remove(at: alertsToDelete.lastIndex(of: cdStockieUserObject.alerts[i])!)
                    alertsToAppend.remove(at: alertsToAppend.lastIndex(of: stockieUserObject.alerts[j])!)
                    alertsToUpdate.append(stockieUserObject.alerts[j])
                }
            }
        }
        
        for alertToDelete in alertsToDelete { try remove(alertByID: alertToDelete.alertID) }
        for alertToAppend in alertsToAppend { try save(alertObject: alertToAppend, toUsername: stockieUserObject.username) }
        for alertToUpdate in alertsToUpdate { try update(alertAttributes: alertToUpdate, toUsername: stockieUserObject.username) }
        
        try update(stockieUserAttributes: stockieUserObject)
        
//        if cdStockieUserObject == stockieUserObject {
//            return
//        }
//
//        try update(watchlists: stockieUserObject.watchlists, forUsername: stockieUserObject.username)
//
//        if cdStockieUserObject.watchlists != stockieUserObject.watchlists {
//            for networkWatchlist in stockieUserObject.watchlists {
//                //Loop through Watchlist []
//
//                if !cdStockieUserObject.watchlists.contains(networkWatchlist) {
//                    //If Watchlist is not existant in the CoreData Watchlist []
//                    //This means that the Watchilst is either:
//                    //      NEW and should be saved
//                    //      MODIFIED and should be updated
//
//                    var found = false
//                    var index = 0
//                    for _ in 0..<cdStockieUserObject.watchlists.count {
//                        let cdWatchlistObject = cdStockieUserObject.watchlists[index]
//
//                        if cdWatchlistObject.watchlistID == networkWatchlist.watchlistID {
//                            //The Watchlist is MODIFIED if there is another Watchilst with the same WatchlistID
//
//                            try update(watchlist: networkWatchlist, forUsername: stockieUserObject.username)
//                            cdStockieUserObject.watchlists.remove(at: index)
//
//                            found = true
//                        } else { index += 1 }
//                    }
//
//                    if !found {
//                        //The Watchlist is NEW if there is no other Watchlist with the same WatchlistID
//                        try save(watchlistObject: networkWatchlist, toUsername: stockieUserObject.username)
//                    }
//                }
//            }
            
//            for i in 0..<cdStockieUserObject.watchlists.count {
//                //Loop through CoreData Watchlist []
//                let cdWatchlistObject = cdStockieUserObject.watchlists[i]
//
//                if !stockieUserObject.watchlists.contains(cdWatchlistObject) {
//                    //If CoreData Watchlist is not existant in the Watchlist []
//                    //This means that the Watchlist has been REMOVED
//
//                    try remove(watchlistByID: cdWatchlistObject.watchlistID)
//                    cdStockieUserObject.watchlists.remove(at: i)
//                }
//            }
//        }
//
//        if cdStockieUserObject.alerts != stockieUserObject.alerts {
//            for alertObject in stockieUserObject.alerts {
//                //Loop through Alert []
//
//                if !cdStockieUserObject.alerts.contains(alertObject) {
//                    //If Alert is not existant in the CoreData Alert []
//                    //This means that the Alert is either:
//                    //      NEW and should be saved
//                    //      MODIFIED and should be updated
//
//                    var found = false
//                    for i in 0..<cdStockieUserObject.alerts.count {
//                        let cdAlertObject = cdStockieUserObject.alerts[i]
//
//                        if cdAlertObject.alertID == alertObject.alertID {
//                            //The Watchlist is MODIFIED if there is another Watchilst with the same WatchlistID
//
//                            try update(alertAttributes: alertObject, toStockieUserObject: stockieUserObject)
//                            cdStockieUserObject.alerts.remove(at: i)
//                            found = true
//                        }
//                    }
//
//                    if !found {
//                        //The Watchlist is NEW if there is no other Watchlist with the same WatchlistID
//                        try save(alertObject: alertObject, toStockieUserObject: stockieUserObject)
//                    }
//                }
//            }
//
//            for i in 0..<cdStockieUserObject.alerts.count {
//                //Loop through CoreData Watchlist []
//                let cdAlertObject = cdStockieUserObject.alerts[i]
//
//                if !stockieUserObject.alerts.contains(cdAlertObject) {
//                    //If CoreData Watchlist is not existant in the Watchlist []
//                    //This means that the Watchlist has been REMOVED
//
//                    try remove(alertByID: cdAlertObject.alertID)
//                    cdStockieUserObject.alerts.remove(at: i)
//                }
//            }
//        }
//
//        try update(stockieUserAttributes: stockieUserObject)
    }
    
    /**
     * Updates an individual Watchlist Object in CoreData
     *
     * Actions:
     *      UPDATE ALL Stocks with new values
     *      ASSOCIATE Stock with Watchlist if it does not exist in CoreData
     *      REMOVE Stock's association with Watchlist if it does not exist in WatchlistObject.stocks Array
     */
    static func update(watchlist watchlistObject: WatchlistObject, forUsername username: String) throws {
        let managedContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        managedContext.parent = staticManagedContext
        
        let cdWatchlistObject = try getWatchlist(forWatchlistID: watchlistObject.watchlistID, andUsername: username)
        
        var stocksToDelete : [StockObject] = NSArray(array: cdWatchlistObject.stocks) as! [StockObject]
        var stocksToAppend : [StockObject] = NSArray(array: watchlistObject.stocks) as! [StockObject]
        var stocksToUpdate : [StockObject] = []
        
        for i in 0..<cdWatchlistObject.stocks.count {
            for j in 0..<watchlistObject.stocks.count {
                if cdWatchlistObject.stocks[i].symbol == watchlistObject.stocks[j].symbol {
                    stocksToDelete.remove(at: stocksToDelete.lastIndex(of: cdWatchlistObject.stocks[i])!)
                    stocksToAppend.remove(at: stocksToAppend.lastIndex(of: watchlistObject.stocks[j])!)
                    stocksToUpdate.append(watchlistObject.stocks[j])
                }
            }
        }
        
        for stockToDelete in stocksToDelete { try remove(watchlistStockAssociationByWatchlistID: cdWatchlistObject.watchlistID, symbol: stockToDelete.symbol)}
        for stockToAppend in stocksToAppend { try save(stockObject: stockToAppend, toWatchlistObject: cdWatchlistObject) }
        for stockToUpdate in stocksToUpdate { try update(stockAttributes: stockToUpdate) }
        
        try update(watchlistAttributes: watchlistObject)
    }
    
    private static func update(stockieUserAttributes stockieUserObject: StockieUserObject) throws {
        let managedContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        managedContext.parent = staticManagedContext
        
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "StockieUser")
        let predicate = NSPredicate(format: "username == %@", stockieUserObject.username)
        fetchRequest.predicate = predicate
        
        let objects = try managedContext.fetch(fetchRequest)
        if objects.count > 1 { throw CoreDataHandlerErrors.duplicateUser(username: stockieUserObject.username) }
        if objects.count == 0 { throw CoreDataHandlerErrors.invalidUser(username: stockieUserObject.username) }
        let object = objects[0] as NSManagedObject
        
        object.setValue(stockieUserObject.identityToken, forKey: "identityToken")
        object.setValue(stockieUserObject.username, forKey: "username")
        
        try managedContext.save()
        
        asyncSave()
    }
    
    private static func update(watchlistAttributes watchlistObject: WatchlistObject) throws {
        let managedContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        managedContext.parent = staticManagedContext
        
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Watchlist")
        let predicate = NSPredicate(format: "watchlistID == %@", watchlistObject.watchlistID)
        fetchRequest.predicate = predicate
        
        let objects = try managedContext.fetch(fetchRequest)
        if objects.count > 1 { throw CoreDataHandlerErrors.duplicateWatchlist(watchlistID: watchlistObject.watchlistID) }
        if objects.count == 0 { throw CoreDataHandlerErrors.invalidWatchlist(watchlistID: watchlistObject.watchlistID) }
        let object = objects[0] as NSManagedObject
        
        object.setValue(watchlistObject.name, forKey: "name")
        
        try managedContext.save()
        
        asyncSave()
    }
    
    static func update(stockAttributes stockObject: StockObject) throws {
        let managedContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        managedContext.parent = staticManagedContext
        
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Stock")
        let predicate = NSPredicate(format: "symbol == %@", stockObject.symbol)
        fetchRequest.predicate = predicate
        
        let objects = try managedContext.fetch(fetchRequest)
        if objects.count > 1 { throw CoreDataHandlerErrors.duplicateStock(symbol: stockObject.symbol) }
        if objects.count == 0 { throw CoreDataHandlerErrors.invalidStock(symbol: stockObject.symbol) }
        let object = objects[0] as NSManagedObject
        
        object.setValue(stockObject.company, forKey: "company")
        object.setValue(stockObject.lastPrice, forKey: "lastPrice")
        
        try managedContext.save()
        
        asyncSave()
    }
    
    private static func update(alertAttributes alertObject: AlertObject, toUsername username: String) throws {
        let managedContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        managedContext.parent = staticManagedContext
        
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Alert")
        let predicate = NSPredicate(format: "alertID == %@", alertObject.alertID)
        fetchRequest.predicate = predicate
        
        let objects = try managedContext.fetch(fetchRequest)
        if objects.count > 1 { throw CoreDataHandlerErrors.duplicateAlert(alertID: alertObject.alertID) }
        if objects.count == 0 { throw CoreDataHandlerErrors.invalidAlert(alertID: alertObject.alertID) }
        let object = objects[0] as NSManagedObject
        
        object.setValue(username, forKey: "username")
        object.setValue(alertObject.symbol, forKey: "symbol")
        object.setValue(alertObject.price, forKey: "price")
        object.setValue(alertObject.overPrice, forKey: "overPrice")
        object.setValue(alertObject.executed, forKey: "executed")
        object.setValue(alertObject.hidden, forKey: "hidden")
        
        try managedContext.save()
        
        asyncSave()
    }
    
    
    //MARK: - Getting individual objects from Core Data
    
    static func getStockieUserObject(forUsername username: String) throws -> StockieUserObject {
        let managedContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        managedContext.parent = staticManagedContext
        
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "StockieUser")
        let predicate = NSPredicate(format: "username == %@", username)
        fetchRequest.predicate = predicate
        
        let objects = try managedContext.fetch(fetchRequest)
        if objects.count > 1 { throw CoreDataHandlerErrors.duplicateUser(username: username) }
        if objects.count == 0 { throw CoreDataHandlerErrors.invalidUser(username: username) }
        
        guard let identityToken = objects[0].value(forKey: "identityToken") as? String else { throw CoreDataHandlerErrors.invalidUser(username: username) }
                        
        return try StockieUserObject(identityToken: identityToken, username: username, watchlists: getWatchlists(forUsername: username), alerts: getAlerts(forUsername: username))
    }
    
    static func getWatchlist(forWatchlistID watchlistID: String, andUsername username: String) throws -> WatchlistObject {
        let managedContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        managedContext.parent = staticManagedContext
        
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Watchlist")
        let predicate = NSPredicate(format: "watchlistID == %@ && username == %@", watchlistID, username)
        fetchRequest.predicate = predicate
        
        let objects = try managedContext.fetch(fetchRequest)
        if objects.count > 1 { throw CoreDataHandlerErrors.duplicateWatchlist(watchlistID: watchlistID) }
        if objects.count == 0 { throw CoreDataHandlerErrors.invalidWatchlist(watchlistID: watchlistID) }
        
        guard let name = objects[0].value(forKey: "name") as? String, let isDefault = objects[0].value(forKey: "isDefault") as? Bool else { throw CoreDataHandlerErrors.invalidWatchlist(watchlistID: watchlistID) }
                        
        return try WatchlistObject(name: name, watchlistID: watchlistID, isDefault: isDefault, stocks: getStocks(forWatchlistID: watchlistID))
    }
    
    static func getDefaultWatchlist(forUsername username: String) throws -> WatchlistObject {
        let managedContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        managedContext.parent = staticManagedContext
        
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Watchlist")
        let predicate = NSPredicate(format: "isDefault == true && username == %@", username)
        fetchRequest.predicate = predicate
        
        let objects = try managedContext.fetch(fetchRequest)
        if objects.count > 1 { throw CoreDataHandlerErrors.duplicateDefaultWatchlist(username: username) }
        if objects.count == 0 { throw CoreDataHandlerErrors.invalidDefaultWatchlist(username: username) }
        
        guard let name = objects[0].value(forKey: "name") as? String, let watchlistID = objects[0].value(forKey: "watchlistID") as? String else { throw CoreDataHandlerErrors.invalidDefaultWatchlist(username: username) }
                        
        return try WatchlistObject(name: name, watchlistID: watchlistID, isDefault: true, stocks: getStocks(forWatchlistID: watchlistID))
    }
    
    static func getStock(forSymbol symbol: String) throws -> StockObject {
        let managedContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        managedContext.parent = staticManagedContext
        
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Stock")
        let predicate = NSPredicate(format: "symbol == %@", symbol)
        fetchRequest.predicate = predicate
        
        let objects = try managedContext.fetch(fetchRequest)
        if objects.count > 1 { throw CoreDataHandlerErrors.duplicateStock(symbol: symbol) }
        if objects.count == 0 { throw CoreDataHandlerErrors.invalidStock(symbol: symbol) }
        guard let company = objects[0].value(forKey: "company") as? String, let lastPrice = objects[0].value(forKey: "lastPrice") as? Double else { throw CoreDataHandlerErrors.invalidStock(symbol: symbol) }
        
        return StockObject(company: company, symbol: symbol, lastPrice: lastPrice)
    }
    
    static func getAlert(forAlertID alertID: String) throws -> AlertObject {
        let managedContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        managedContext.parent = staticManagedContext
        
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Alert")
        let predicate = NSPredicate(format: "alertID == %@", alertID)
        fetchRequest.predicate = predicate
        
        let objects = try managedContext.fetch(fetchRequest)
        if objects.count > 1 { throw CoreDataHandlerErrors.duplicateAlert(alertID: alertID) }
        if objects.count == 0 { throw CoreDataHandlerErrors.invalidAlert(alertID: alertID) }
        guard let symbol = objects[0].value(forKey: "symbol") as? String, let price = objects[0].value(forKey: "price") as? Double, let overPrice = objects[0].value(forKey: "overPrice") as? Bool, let executed = objects[0].value(forKey: "executed") as? Bool, let hidden = objects[0].value(forKey: "hidden") as? Bool else { throw CoreDataHandlerErrors.invalidAlert(alertID: alertID) }
        
        return AlertObject(alertID: alertID, symbol: symbol, price: price, overPrice: overPrice, executed: executed, hidden: hidden)
    }
    
    
    //MARK: - Getting object arrays from Core Data
    
    static func getUserObjects() throws -> [StockieUserObject] {
        let managedContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        managedContext.parent = staticManagedContext
        
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "StockieUser")
        var users : [StockieUserObject] = []
        
        let objects = try managedContext.fetch(fetchRequest)
        
        for object in objects {
            if let identityToken = object.value(forKey: "identityToken") as? String, let username = object.value(forKey: "username") as? String {
                try users.append(StockieUserObject(identityToken: identityToken, username: username, watchlists: getWatchlists(forUsername: username), alerts: getAlerts(forUsername: username)))
            } else {
                managedContext.delete(object)
                
                try managedContext.save()
                
                asyncSave()
                
                print("Deleted invalid User.")
            }
        }
        
        
        return users
    }
    
    static func getWatchlists(forUsername username: String) throws -> [WatchlistObject] {
        let managedContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        managedContext.parent = staticManagedContext
        
        var watchlists : [WatchlistObject] = []
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Watchlist")
        let predicate = NSPredicate(format: "username == %@", username)
        fetchRequest.predicate = predicate;
        
        let objects = try managedContext.fetch(fetchRequest)
        
        for object in objects {
            if let name = object.value(forKey: "name") as? String, let watchlistID = object.value(forKey: "watchlistID") as? String, let isDefault = object.value(forKey: "isDefault") as? Bool {
                try watchlists.append(WatchlistObject(name: name, watchlistID: watchlistID, isDefault: isDefault, stocks: getStocks(forWatchlistID: watchlistID)))
            } else {
                managedContext.delete(object)
                
                try managedContext.save()
                
                asyncSave()
                
                print("Deleted invalid Watchlist.")
            }
        }
        
        return watchlists
    }
    
    static func getStocks(forWatchlistID watchlistID: String) throws -> [StockObject] {
        let managedContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        managedContext.parent = staticManagedContext
        
        var stocks : [StockObject] = []
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "WatchlistStock")
        let predicate = NSPredicate(format: "watchlistID == %@", watchlistID)
        fetchRequest.predicate = predicate
        
        let objects = try managedContext.fetch(fetchRequest)
        
        for object in objects {
            if let symbol = object.value(forKey: "symbol") as? String {
                try stocks.append(getStock(forSymbol: symbol))
            } else {
                managedContext.delete(object)
                
                try managedContext.save()
                
                asyncSave()
                
                print("Deleted invalid Stock.")
            }
        }
        
        return stocks
    }
    
    static func getAllStocks() throws -> [StockObject] {
        let managedContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        managedContext.parent = staticManagedContext
        
        var stocks : [StockObject] = []
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Stock")
        
        let objects = try managedContext.fetch(fetchRequest)
        for object in objects {
            guard let company = object.value(forKey: "company") as? String, let symbol = object.value(forKey: "symbol") as? String, let lastPrice = object.value(forKey: "lastPrice") as? Double else {
                print("A value was nil when looping through Stock entity in CoreData!")
                return []
            }
            
            stocks.append(StockObject(company: company, symbol: symbol, lastPrice: lastPrice))
        }
        
        return stocks
    }
    
    static func getAlerts(forSymbol symbol: String, andUsername username: String, isExecuted: Bool) throws -> [AlertObject] {
        let managedContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        managedContext.parent = staticManagedContext
        
        var alerts : [AlertObject] = []
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Alert")
        let predicate = NSPredicate(format: "symbol == %@ && username == %@ && executed == %@", symbol, username, isExecuted)
        fetchRequest.predicate = predicate
        
        let objects = try managedContext.fetch(fetchRequest)
        
        for object in objects {
            if let alertID = object.value(forKey: "alertID") as? String, let price = object.value(forKey: "price") as? Double, let overPrice = object.value(forKey: "overPrice") as? Bool, let hidden = object.value(forKey: "hidden") as? Bool {
                
                alerts.append(AlertObject(alertID: alertID, symbol: symbol, price: price, overPrice: overPrice, executed: isExecuted, hidden: hidden))
            } else {
                managedContext.delete(object)
                
                try managedContext.save()
                
                asyncSave()
                
                print("Deleted invalid Alert.")
            }
        }
        
        return alerts
    }
    
    static func getAlerts(forSymbol symbol: String, andUsername username: String, isHidden: Bool) throws -> [AlertObject] {
        let managedContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        managedContext.parent = staticManagedContext
        
        var alerts : [AlertObject] = []
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Alert")
        let predicate = NSPredicate(format: "symbol == %@ && username == %@ && hidden == %@", symbol, username, isHidden)
        fetchRequest.predicate = predicate
        
        let objects = try managedContext.fetch(fetchRequest)
        
        for object in objects {
            if let alertID = object.value(forKey: "alertID") as? String, let price = object.value(forKey: "price") as? Double, let overPrice = object.value(forKey: "overPrice") as? Bool, let executed = object.value(forKey: "executed") as? Bool {
                
                alerts.append(AlertObject(alertID: alertID, symbol: symbol, price: price, overPrice: overPrice, executed: executed, hidden: isHidden))
            } else {
                managedContext.delete(object)
                
                try managedContext.save()
                
                asyncSave()
                
                print("Deleted invalid Alert.")
            }
        }
        
        return alerts
    }
    
    static func getAlerts(forSymbol symbol: String, andUsername username: String, isExecuted: Bool, isHidden: Bool) throws -> [AlertObject] {
        let managedContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        managedContext.parent = staticManagedContext
        
        var alerts : [AlertObject] = []
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Alert")
        let predicate = NSPredicate(format: "symbol == %@ && username == %@ && executed == %@ && hidden == %@", symbol, username, isExecuted, isHidden)
        fetchRequest.predicate = predicate
        
        let objects = try managedContext.fetch(fetchRequest)
        
        for object in objects {
            if let alertID = object.value(forKey: "alertID") as? String, let price = object.value(forKey: "price") as? Double, let overPrice = object.value(forKey: "overPrice") as? Bool {
                
                alerts.append(AlertObject(alertID: alertID, symbol: symbol, price: price, overPrice: overPrice, executed: isExecuted, hidden: isHidden))
            } else {
                managedContext.delete(object)
                
                try managedContext.save()
                
                asyncSave()
                
                print("Deleted invalid Alert.")
            }
        }
        
        return alerts
    }
    
    static func getAlerts(forUsername username: String) throws -> [AlertObject] {
        let managedContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        managedContext.parent = staticManagedContext
        
        var alerts : [AlertObject] = []
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Alert")
        let predicate = NSPredicate(format: "username == %@", username)
        fetchRequest.predicate = predicate
        
        let objects = try managedContext.fetch(fetchRequest)
        
        for object in objects {
            if let alertID = object.value(forKey: "alertID") as? String, let symbol = object.value(forKey: "symbol") as? String, let price = object.value(forKey: "price") as? Double, let overPrice = object.value(forKey: "overPrice") as? Bool, let isExecuted = object.value(forKey: "executed") as? Bool, let isHidden = object.value(forKey: "hidden") as? Bool {
                
                alerts.append(AlertObject(alertID: alertID, symbol: symbol, price: price, overPrice: overPrice, executed: isExecuted, hidden: isHidden))
            } else {
                managedContext.delete(object)
                
                try managedContext.save()
                
                asyncSave()
                
                print("Deleted invalid Alert.")
            }
        }
        
        return alerts
    }
    
    static func getIdentityToken(_ username: String) throws -> String {
        let managedContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        managedContext.parent = staticManagedContext
        
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "StockieUser")
        let predicate = NSPredicate(format: "username == %@", username)
        fetchRequest.predicate = predicate
        
        let objects = try managedContext.fetch(fetchRequest)
        
        for object in objects {
            if let identityToken = object.value(forKey: "identityToken") as? String {
                return identityToken
            }
        }
        
        return ""
    }
    
    
    //MARK: - Checking for Existance in Core Data

    static func watchlistStockAssociationExists(forWatchlistID watchlistID: String, andSymbol symbol: String) throws -> Bool {
        let managedContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        managedContext.parent = staticManagedContext
        
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "WatchlistStock")
        let predicate = NSPredicate(format: "symbol == %@ && watchlistID == %@", symbol, watchlistID)
        fetchRequest.predicate = predicate

        let objects = try managedContext.fetch(fetchRequest)
        if objects.count > 1 { throw CoreDataHandlerErrors.duplicateWatchlistStockAssociations(watchlistID: watchlistID, symbol: symbol) }
        if objects.count == 1 {
            if let _ = objects[0].value(forKey: "watchlistID") as? String, let _ = objects[0].value(forKey: "symbol") as? String {
                return true
            }
        }

        return false
    }
    
    static func stockExists(symbol: String) throws -> Bool {
        do {
            try getStock(forSymbol: symbol)
            return true
        } catch CoreDataHandlerErrors.invalidStock {
            return false
        }
    }
    
    
    //MARK: - Removing from Core Data
    
    static func remove(stockieUser username: String) throws {
        let managedContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        managedContext.parent = staticManagedContext
        
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "StockieUser")
        let predicate = NSPredicate(format: "username == %@", username)
        fetchRequest.predicate = predicate
        
        let objects = try managedContext.fetch(fetchRequest)
        
        for object in objects {
            managedContext.delete(object)
            
            try managedContext.save()
            
            asyncSave()
        }
    }
    
    static func remove(watchlistByID watchlistID: String) throws {
        let managedContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        managedContext.parent = staticManagedContext
        
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Watchlist")
        let predicate = NSPredicate(format: "watchlistID == %@", watchlistID)
        fetchRequest.predicate = predicate
        
        let objects = try managedContext.fetch(fetchRequest)
        
        for object in objects {
            managedContext.delete(object)
            
            try managedContext.save()
            
            asyncSave()
        }
    }
    
    static func remove(stockByID stockID: String) throws {
        let managedContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        managedContext.parent = staticManagedContext
        
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Stock")
        let predicate = NSPredicate(format: "stockID == %@", stockID)
        fetchRequest.predicate = predicate
        
        let objects = try managedContext.fetch(fetchRequest)
        
        for object in objects {
            managedContext.delete(object)
            
            try managedContext.save()
            
            asyncSave()
        }
    }
    
    static func remove(watchlistStockAssociationByWatchlistID watchlistID: String, symbol: String) throws {
        let managedContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        managedContext.parent = staticManagedContext
        
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "WatchlistStock")
        let predicate = NSPredicate(format: "watchlistID == %@ && symbol == %@", watchlistID, symbol)
        fetchRequest.predicate = predicate
        
        let objects = try managedContext.fetch(fetchRequest)
        
        for object in objects {
            managedContext.delete(object)
            
            try managedContext.save()
            
            asyncSave()
        }
    }
    
    static func remove(alertByID alertID: String) throws {
        let managedContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        managedContext.parent = staticManagedContext
        
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Alert")
        let predicate = NSPredicate(format: "alertID == %@", alertID)
        fetchRequest.predicate = predicate
        
        let objects = try managedContext.fetch(fetchRequest)
        
        for object in objects {
            managedContext.delete(object)
            
            try managedContext.save()
            
            asyncSave()
        }
        
        asyncSave()
    }
    
    static func asyncSave() {
        DispatchQueue.main.async {
            do {
                try staticManagedContext.save()
            } catch {
                print("Error saving staticManagedContext: \(error)")
            }
        }
    }
}
