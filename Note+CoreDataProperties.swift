//
//  Note+CoreDataProperties.swift
//  iDraw
//
//  Created by Nwaokocha Victor on 2020-12-05.
//  Copyright © 2020 Apple. All rights reserved.
//
//

import Foundation
import CoreData


extension Note {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Note> {
        return NSFetchRequest<Note>(entityName: "Note")
    }

    @NSManaged public var canvasHeight: Double
    @NSManaged public var canvasWidth: Double
    @NSManaged public var dateModified: Date?
    @NSManaged public var drawing: Data?
    @NSManaged public var uuid: UUID?

}

extension Note : Identifiable {

}
