//
//  Note+CoreDataProperties.swift
//  iDraw
//
//  Created by Nwaokocha Victor on 2020-11-26.
//  Copyright © 2020 Apple. All rights reserved.
//
//

import Foundation
import CoreData


extension Note {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Note> {
        return NSFetchRequest<Note>(entityName: "Note")
    }

    @NSManaged public var uuid: String?
    @NSManaged public var drawing: PKDrawing?
    @NSManaged public var canvasWidth: Double
    @NSManaged public var canvasHeight: Double

}

extension Note : Identifiable {

}
