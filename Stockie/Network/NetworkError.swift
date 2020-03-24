//
//  NetworkError.swift
//  Stockie
//
//  Created by Alex Coundouriotis on 2/25/20.
//  Copyright © 2020 Alex Coundouriotis. All rights reserved.
//

import Foundation

enum NetworkError {
    case Unknown
    case Null
    case Success
    case MissingKey
    case InvalidValue
    case InvalidCredentials
    case InvalidIdentifier
    case DuplicateObject
    case DuplicateIdentifier
    case Association
    case DateTimeParse
    case SQL
    case InvalidUsername
    case ExpiredIdentity
}
