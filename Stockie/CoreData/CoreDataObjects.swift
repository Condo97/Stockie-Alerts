//
//  StokieUser.swift
//  Stockie
//
//  Created by Alex Coundouriotis on 2/25/20.
//  Copyright © 2020 Alex Coundouriotis. All rights reserved.
//

import UIKit

struct StockieUserObject : Equatable {
    static func == (lhs: StockieUserObject, rhs: StockieUserObject) -> Bool {
        return lhs.identityToken == rhs.identityToken && lhs.username == rhs.username && lhs.watchlists == rhs.watchlists && lhs.alerts == rhs.alerts
    }
    
    var identityToken = String()
    var username = String()
    var watchlists : [WatchlistObject] = []
    var alerts : [AlertObject] = []
}

struct WatchlistObject : Equatable {
    static func == (lhs: WatchlistObject, rhs: WatchlistObject) -> Bool {
        return lhs.name == rhs.name && lhs.watchlistID == rhs.watchlistID && lhs.isDefault == rhs.isDefault && lhs.stocks == rhs.stocks
    }
    
    var name = String()
    var watchlistID = String()
    var isDefault = false
    var stocks : [StockObject]
}

struct StockObject : Equatable {
    static func == (lhs: StockObject, rhs: StockObject) -> Bool {
        return lhs.company == rhs.company && lhs.symbol == rhs.symbol
    }
    
    var company = String()
    var symbol = String()
    var lastPrice = Double()
}

struct AlertObject : Equatable {
    static func == (lhs: AlertObject, rhs: AlertObject) -> Bool {
        return lhs.alertID == rhs.alertID && lhs.symbol == rhs.symbol && lhs.price == rhs.price && lhs.overPrice == rhs.overPrice && lhs.executed == rhs.executed && lhs.hidden == rhs.hidden
    }
    
    var alertID = String()
    var symbol = String()
    var price = Double()
    var overPrice = Bool()
    var executed = Bool()
    var hidden = Bool()
}
