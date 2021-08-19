//
//  NotebookMo.swift
//  ProyectoPersistencia
//
//  Created by jose manuel carreiro galicia on 20/7/21.
//

import Foundation
import CoreData

@objc
public class NotebookMO: NSManagedObject {

    public override func awakeFromInsert() {
        super.awakeFromInsert()

        print("se creo un notebook.")
    }

    public override func didTurnIntoFault() {
        super.didTurnIntoFault()

        print("se creo un fault.")
    }

    @discardableResult
    static func createNotebook(createdAt: Date,
                               title: String,
                               in managedObjectContext: NSManagedObjectContext) -> NotebookMO? {
        let notebook = NSEntityDescription.insertNewObject(forEntityName: "Notebook",
                                                           into: managedObjectContext) as? NotebookMO
        notebook?.createAt = createdAt
        notebook?.title = title
        return notebook
    }
}

