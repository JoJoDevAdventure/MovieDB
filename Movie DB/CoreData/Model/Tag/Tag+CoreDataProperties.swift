//
//  Tag+CoreDataProperties.swift
//  Movie DB
//
//  Created by Jonas Frey on 07.02.21.
//  Copyright © 2021 Jonas Frey. All rights reserved.
//
//

import Foundation
import CoreData


extension Tag {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Tag> {
        return NSFetchRequest<Tag>(entityName: "Tag")
    }

    // TODO: Change IDs to UUIDs
    /// The ID of the tag
    @NSManaged public var id: UUID
    /// The name of the tag
    @NSManaged public var name: String
    @NSManaged public var filterSettings: Set<FilterSetting>

}

extension Tag : Identifiable {

}
