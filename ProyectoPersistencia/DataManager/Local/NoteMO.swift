//
//  NoteMO.swift
//  ProyectoPersistencia
//
//  Created by jose manuel carreiro galicia on 02/8/21.
//

import Foundation
import CoreData

@objc
public class NoteMO: NSManagedObject {

    @discardableResult
    static func createNote(managedObjectContext: NSManagedObjectContext,
                           notebook: NotebookMO,
                           title: String,
                           contents: String,
                           createdAt: Date) -> NoteMO? {
        let note = NSEntityDescription.insertNewObject(forEntityName: "Note",
                                                       into: managedObjectContext) as? NoteMO

        note?.title = title
        note?.contents = contents
        note?.createAt = createdAt
        note?.notebook = notebook

        return note
    }
}
