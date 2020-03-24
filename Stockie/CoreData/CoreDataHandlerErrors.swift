//
//  CoreDataErrors.swift
//  Stockie
//
//  Created by Alex Coundouriotis on 3/2/20.
//  Copyright © 2020 Alex Coundouriotis. All rights reserved.
//

import Foundation

enum CoreDataHandlerErrors : Error {
    case invalidUser(username: String)
    case invalidDefaultWatchlist(username: String)
    case invalidWatchlist(watchlistID: String)
    case invalidStock(symbol: String)
    case invalidWatchlistStockAssociation(watchlistID: String, symbol: String)
    case invalidUserWatchlistAssociation(username: String, watchlistID: String)
    case invalidAlert(alertID: String)
    
    case duplicateUser(username: String)
    case duplicateDefaultWatchlist(username: String)
    case duplicateWatchlist(watchlistID: String)
    case duplicateStock(symbol: String)
    case duplicateWatchlistStockAssociations(watchlistID: String, symbol: String)
    case duplicateAlert(alertID: String)
}
