//
//  NetworkHandler.swift
//  Stockie
//
//  Created by Alex Coundouriotis on 2/25/20.
//  Copyright © 2020 Alex Coundouriotis. All rights reserved.
//

import UIKit

class NetworkHandler: NSObject {
    static let baseURL = "https://stokieapp.com/"
    static let networkErrors = [-1: NetworkError.Null,
                                0: NetworkError.Success,
                                1: NetworkError.Unknown,
                                40: NetworkError.MissingKey,
                                41: NetworkError.InvalidValue,
                                50: NetworkError.InvalidUsername,
                                51: NetworkError.InvalidIdentifier,
                                53: NetworkError.DuplicateObject,
                                54: NetworkError.DuplicateIdentifier,
                                55: NetworkError.Association,
                                56: NetworkError.DateTimeParse,
                                57: NetworkError.ExpiredIdentity,
                                59: NetworkError.SQL]
    
    static func createRequest(_ postJSON: [String: Any], _ path: String) -> URLRequest {
        var request = URLRequest(url: URL(string: baseURL + path)!)
        request.httpBody = try? JSONSerialization.data(withJSONObject: postJSON)
        request.httpMethod = "POST"
        
        return request
    }
    
    static func parseError(_ json: [String: Any]?) -> NetworkError {
        return networkErrors[json?["Error"] as? Int ?? -1] ?? NetworkError.Unknown
    }
    
    
    //MARK: - User Flow
    
    static func addUser(_ username: String, password: String, completion: @escaping(_ stokieUserObject: StockieUserObject?, _ error: NetworkError) -> Void) {
        let postJSON: [String: Any] = [
                "Username": username,
                "Password": password
        ]
        
        let task = URLSession.shared.dataTask(with: createRequest(postJSON, "createUser")) {
            data, response, error in
            guard let data = data, error == nil else { return }
            
            let responseJSON = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
            
            let responseError = parseError(responseJSON)
            guard let identityToken = responseJSON?["IdentityToken"] as? String else {
                completion(StockieUserObject(), responseError)
                return
            }
            
            getWatchlists(identityToken) {
                watchlists, error in
                let userObject = StockieUserObject(identityToken: identityToken, username: username, watchlists: watchlists)
                completion(userObject, responseError)
            }
        }
        
        task.resume()
    }
    
    static func checkUser(_ username: String, completion: @escaping(_ error: NetworkError) -> Void) {
        let postJSON: [String: Any] = [
                "Username": username
        ]
        
        let task = URLSession.shared.dataTask(with: createRequest(postJSON, "checkUser")) {
            data, response, error in
            guard let data = data, error == nil else { return }
            
            let responseJSON = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
            
            let responseError = parseError(responseJSON)
            
            completion(responseError)
        }
        
        task.resume()
    }
    
    static func userLogin(_ username: String, password: String, completion: @escaping(_ stokieUserObject: StockieUserObject?, _ error: NetworkError) -> Void) {
        let postJSON: [String: Any] = [
                "Username": username,
                "Password": password
        ]
        
        let task = URLSession.shared.dataTask(with: createRequest(postJSON, "userLogin")) {
            data, response, error in
            guard let data = data, error == nil else { return }
            
            let responseJSON = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
            
            let responseError = parseError(responseJSON)
            guard let identityToken = responseJSON?["IdentityToken"] as? String else {
                completion(StockieUserObject(), responseError)
                return
            }
            
            getWatchlists(identityToken) {
                watchlists, error in
                
                getAlerts(identityToken) {
                    alerts, error in
                    
                    let userObject = StockieUserObject(identityToken: identityToken, username: username, watchlists: watchlists, alerts: alerts ?? [])
                    completion(userObject, responseError)
                }
            }
        }
        
        task.resume()
    }
    
    static func addDeviceToken(_ identityToken: String, deviceToken: String, completion: @escaping(_ errror: NetworkError) -> Void) {
        let postJSON: [String: Any] = [
            "IdentityToken": identityToken,
            "DeviceToken": deviceToken
        ]
        
        let task = URLSession.shared.dataTask(with: createRequest(postJSON, "addDeviceToken")) {
            data, response, error in
            guard let data = data, error == nil else { return }
            
            let responseJSON = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
            
            let responseError = parseError(responseJSON)
            
            completion(responseError)
        }
        
        task.resume()
    }
    
    static func removeDeviceToken(_ identityToken: String, deviceToken: String, completion: @escaping(_ error: NetworkError) -> Void) {
        let postJSON: [String: Any] = [
            "IdentityToken": identityToken,
            "DeviceToken": deviceToken
        ]
        
        let task = URLSession.shared.dataTask(with: createRequest(postJSON, "removeDeviceToken")) {
            data, response, error in
            guard let data = data, error == nil else { return }
            
            let responseJSON = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
            
            completion(parseError(responseJSON))
        }
        
        task.resume()
    }
    
    
    //MARK: - Watchlist Flow
    
    static func getWatchlists(_ identityToken: String, completion: @escaping(_ watchlists: [WatchlistObject], _ error: NetworkError) -> Void) {
        let postJSON: [String: Any] = [
            "IdentityToken": identityToken
        ]
        
        let task = URLSession.shared.dataTask(with: createRequest(postJSON, "getWatchlists")) {
            data, response, error in
            guard let theData = data, error == nil else { return }
            
            let responseJSON = try? JSONSerialization.jsonObject(with: theData, options: []) as? [String: Any]
            
            let responseError = parseError(responseJSON)
            guard let watchlists = responseJSON?["Watchlists"] as? [NSDictionary] else {
                completion([], responseError)
                return
            }
            
            var watchlistObjects : [WatchlistObject] = []
            
            for i in 0..<watchlists.count {
                guard let watchlistName = watchlists[i]["WatchlistName"] as? String, let watchlistID = watchlists[i]["WatchlistID"] as? String, let isDefault = watchlists[i]["IsDefault"] as? Bool, let stocks = watchlists[i]["Stocks"] as? [NSDictionary] else {
                    completion([], responseError)
                    return
                }
                
                var stockObjects : [StockObject] = []
                
                for j in 0..<stocks.count {
                    guard let stockCompany = stocks[j]["Company"] as? String, let stockSymbol = stocks[j]["Symbol"] as? String, let stockLastPrice = stocks[j]["LastPrice"] as? Double else {
                        completion([], responseError)
                        return
                    }
                    
                    stockObjects.append(StockObject(company: stockCompany, symbol: stockSymbol, lastPrice: stockLastPrice))
                }
                
                watchlistObjects.append(WatchlistObject(name: watchlistName, watchlistID: watchlistID, isDefault: isDefault, stocks: stockObjects))
            }
            
            completion(watchlistObjects, responseError)
        }
        
        task.resume()
    }
    
    static func addWatchlist(_ identityToken: String, watchlistName: String, isDefault: Bool, completion: @escaping(_ watchlistName: String, _ watchlistID: String, _ error: NetworkError) -> Void) {
        let postJSON: [String: Any] = [
            "IdentityToken": identityToken,
            "WatchlistName": watchlistName,
            "IsDefault": isDefault
        ]
        
        let task = URLSession.shared.dataTask(with: createRequest(postJSON, "addWatchlist")) {
            data, response, error in
            guard let theData = data, error == nil else { return }
            
            let responseJSON = try? JSONSerialization.jsonObject(with: theData, options: []) as? [String: Any]
            
            guard let watchlistName = responseJSON?["WatchlistName"] as? String, let watchlistID = responseJSON?["WatchlistID"] as? String else {
                completion("", "", parseError(responseJSON))
                return
            }
            
            completion(watchlistName, watchlistID, parseError(responseJSON))
        }
        
        task.resume()
    }
    
    static func addStockToWatchlist(_ identityToken: String, watchlistID: String, stockSymbol: String, completion: @escaping(_ error: NetworkError) -> Void) {
        let postJSON: [String: Any] = [
            "IdentityToken": identityToken,
            "WatchlistID": watchlistID,
            "StockSymbol": stockSymbol
        ]
        
        let task = URLSession.shared.dataTask(with: createRequest(postJSON, "addStockToWatchlist")) {
            data, response, error in
            guard let theData = data, error == nil else { return }
            
            let responseJSON = try? JSONSerialization.jsonObject(with: theData, options: []) as? [String: Any]
            
            completion(parseError(responseJSON))
        }
        
        task.resume()
    }
    
    static func getStock(_ identityToken: String, stockSymbol: String, completion: @escaping(_ stock: StockObject?, _ error: NetworkError) -> Void) {
        let postJSON: [String: Any] = [
            "IdentityToken": identityToken,
            "StockSymbol": stockSymbol
        ]
        
        let task = URLSession.shared.dataTask(with: createRequest(postJSON, "getStock")) {
            data, response, error in
            guard let theData = data, error == nil else { return }
            
            let responseJSON = try? JSONSerialization.jsonObject(with: theData, options: []) as? [String: Any]
            
            guard let responseStockSymbol = responseJSON?["StockSymbol"] as? String, let company = responseJSON?["Company"] as? String, let lastPrice = responseJSON?["LastPrice"] as? Double else {
                completion(nil, parseError(responseJSON))
                return
            }
            
            completion(StockObject(company: company, symbol: responseStockSymbol, lastPrice: lastPrice), parseError(responseJSON))
        }
        
        task.resume()
    }
    
    static func getStocks(_ identityToken: String, _ stockSymbols: [String], completion: @escaping(_ stocks: [StockObject]?, _ error: NetworkError) -> Void) {
        let postJSON: [String: Any] = [
            "IdentityToken": identityToken,
            "StockSymbols": stockSymbols
        ]
        
        let task = URLSession.shared.dataTask(with: createRequest(postJSON, "getStocks")) {
            data, response, error in
            guard let theData = data, error == nil else { return }
            
            let responseJSON = try? JSONSerialization.jsonObject(with: theData, options: []) as? [String: Any]
            
            let responseError = parseError(responseJSON)
            guard let stocks = responseJSON?["Stocks"] as? [NSDictionary] else {
                completion(nil, responseError)
                return
            }
            
            var stockObjects : [StockObject] = []
            
            for i in 0..<stocks.count {
                guard let company = stocks[i]["Company"] as? String, let stockSymbol = stocks[i]["StockSymbol"] as? String, let lastPrice = stocks[i]["LastPrice"] as? Double else {
                    completion(nil, responseError)
                    return
                }
                
                stockObjects.append(StockObject(company: company, symbol: stockSymbol, lastPrice: lastPrice))
            }
            
            completion(stockObjects, responseError)
        }
        
        task.resume()
    }
    
    
    //MARK: - Alert Flow
    
    static func getAlerts(_ identityToken: String, completion: @escaping(_ watchlists: [AlertObject]?, _ error: NetworkError) -> Void) {
        let postJSON: [String: Any] = [
            "IdentityToken": identityToken
        ]
        
        let task = URLSession.shared.dataTask(with: createRequest(postJSON, "getAlerts")) {
            data, response, error in
            guard let theData = data, error == nil else { return }
            
            let responseJSON = try? JSONSerialization.jsonObject(with: theData, options: []) as? [String: Any]
            
            let responseError = parseError(responseJSON)
            guard let alerts = responseJSON?["Alerts"] as? [NSDictionary] else {
                completion(nil, responseError)
                return
            }
            
            var alertObjects : [AlertObject] = []
            
            for i in 0..<alerts.count {
                guard let alertID = alerts[i]["AlertID"] as? String, let symbol = alerts[i]["Symbol"] as? String, let price = alerts[i]["Price"] as? Double, let overPrice = alerts[i]["OverPrice"] as? Bool, let executed = alerts[i]["Executed"] as? Bool else {
                    completion(nil, responseError)
                    return
                }
                
                alertObjects.append(AlertObject(alertID: alertID, symbol: symbol, price: price, overPrice: overPrice, executed: executed, hidden: false))
            }
            
            completion(alertObjects, responseError)
        }
        
        task.resume()
    }
    
    static func addAlert(_ identityToken: String, stockSymbol: String, price: Double, completion: @escaping(_ error: NetworkError) -> Void) {
        let postJSON: [String: Any] = [
            "IdentityToken": identityToken,
            "StockSymbol": stockSymbol,
            "Price": price
        ]
        
        let task = URLSession.shared.dataTask(with: createRequest(postJSON, "addAlert")) {
            data, response, error in
            guard let theData = data, error == nil else { return }
            
            let responseJSON = try? JSONSerialization.jsonObject(with: theData, options: []) as? [String: Any]
            
            completion(parseError(responseJSON))
        }
        
        task.resume()
    }
}
