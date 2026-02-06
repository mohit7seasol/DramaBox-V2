//
//  IPTVModel.swift
//  DramaBox
//
//  Created by DREAMWORLD on 05/02/26.
//

struct IPTVGroup: Codable {
    let country: String
    let countryCodes: String
    let flag: String
    let channels: [Channell]
}

struct IPTVCategory: Codable {
    let category: String
    let channels: [Channell]
}

struct Channell: Codable {
    let name: String
    let logo: String?
    let url: String
}
