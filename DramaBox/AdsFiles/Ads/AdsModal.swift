//
//  AdsModal.swift
//  Wireless Display
//
//  Created by Sagar Lukhi on 19/08/23.
//

import Foundation

struct AdsModal : Codable {
    let appopenId : String?
    let nativeId : String?

    enum CodingKeys: String, CodingKey {
        case nativeId = "nativeId"
        case appopenId = "appopenId"
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        appopenId = try values.decodeIfPresent(String.self, forKey: .appopenId)
        nativeId = try values.decodeIfPresent(String.self, forKey: .nativeId)
    }
    
    init(){
        self.appopenId = ""
        self.nativeId = ""
    }

}

struct AdsData: Codable {
    let extraFields: [String: String]
}

//struct CreatedBy : Codable {
//    let _id : String?
//    let name : String?
//
//    enum CodingKeys: String, CodingKey {
//
//        case _id = "_id"
//        case name = "name"
//    }
//
//    init(from decoder: Decoder) throws {
//        let values = try decoder.container(keyedBy: CodingKeys.self)
//        _id = try values.decodeIfPresent(String.self, forKey: ._id)
//        name = try values.decodeIfPresent(String.self, forKey: .name)
//    }
//    
//    init(){
//        self._id = ""
//        self.name = ""
//    }
//
//}


struct UpdatedBy : Codable {
    let _id : String?
    let name : String?

    enum CodingKeys: String, CodingKey {

        case _id = "_id"
        case name = "name"
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        _id = try values.decodeIfPresent(String.self, forKey: ._id)
        name = try values.decodeIfPresent(String.self, forKey: .name)
    }
    
    init(){
        self._id = ""
        self.name = ""
    }

}
