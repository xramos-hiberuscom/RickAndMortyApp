//
//  ServerArray.swift
//  RickAndMortyApp
//
//  Created by Xavier Ramos Sole on 24/11/2026.
//

import Foundation

struct ServerArray<T: Codable>: Codable {
    
    let info: ServerInformation
    let results: [T]
}
