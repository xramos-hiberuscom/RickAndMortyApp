//
//  ServerCharacter.swift
//  RickAndMortyApp
//
//  Created by Xavier Ramos Sole on 24/11/2026.
//

import Foundation

struct ServerCharacter: Codable {
    let id: Int
    let name: String
    let status: String
    let species: String
    let gender: String
    let image: String
    
    func convertToEntity() -> Character {
        Character(id: id,
                  name: name,
                  status: CharacterStatus(rawValue: status) ?? .unknown,
                  species: species,
                  gender: Gender(rawValue: gender) ?? .unknown,
                  image: image)
    }
}
