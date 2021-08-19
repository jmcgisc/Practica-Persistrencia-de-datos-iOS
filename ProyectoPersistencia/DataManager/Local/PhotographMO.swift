//
//  PhotographMO.swift
//  ProyectoPersistencia
//
//  Created by jose manuel carreiro galicia on 03/8/21.
//

import Foundation
import CoreData

@objc
public class PhotographMO: NSManagedObject {

    static func createPhoto(imageData: Data,
                            managedObjectContext: NSManagedObjectContext) -> PhotographMO? {
        let photograph = NSEntityDescription.insertNewObject(forEntityName: "Photograph",
                                                             into: managedObjectContext) as? PhotographMO

        photograph?.imageData = imageData
        photograph?.createAt = Date()

        return photograph
    }
}
