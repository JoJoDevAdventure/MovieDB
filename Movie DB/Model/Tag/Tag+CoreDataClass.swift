//
//  Tag+CoreDataClass.swift
//  Movie DB
//
//  Created by Jonas Frey on 07.02.21.
//  Copyright © 2021 Jonas Frey. All rights reserved.
//
//

import Foundation
import CoreData

/// Represents a user specified tag
@objc(Tag)
public class Tag: NSManagedObject, Decodable {
    
    public required convenience init(from decoder: Decoder) throws {
        guard let context = decoder.userInfo[CodingUserInfoKey.managedObjectContext] as? NSManagedObjectContext else {
            throw DecoderConfigurationError.missingManagedObjectContext
        }
        self.init(context: context)
        
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(Int.self, forKey: .id)
        self.name = try container.decode(String.self, forKey: .name)
    }
    
    public convenience init(id: Int, name: String, context: NSManagedObjectContext) {
        self.init(context: context)
        self.id = id
        self.name = name
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
    }

}
