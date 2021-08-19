//
//  DataController.swift
//  ProyectoPersistencia
//
//  Created by jose manuel carreiro galicia on 01/8/21.
//

import Foundation
import CoreData
import UIKit

class DataController: NSObject {
    private let persistentContainer: NSPersistentContainer

    var viewContext: NSManagedObjectContext {
        return persistentContainer.viewContext
    }

    @discardableResult
    init(modelName: String, optionalStoreName: String?, completionHandler: (@escaping (NSPersistentContainer?) -> ())) {
        if let optionalStoreName = optionalStoreName {
            let managedObjectModel = Self.manageObjectModel(with: modelName)
            self.persistentContainer = NSPersistentContainer(name: optionalStoreName,
                                                             managedObjectModel: managedObjectModel)
            super.init()

            persistentContainer.loadPersistentStores { [weak self] (description, error) in
                if let error = error {
                    fatalError("Couldn't load CoreData Stack \(error.localizedDescription)")
                }

                completionHandler(self?.persistentContainer)
            }

            persistentContainer.performBackgroundTask { (privateMOC) in
            }

        } else {

            self.persistentContainer = NSPersistentContainer(name: modelName)

            super.init()

            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                self?.persistentContainer.loadPersistentStores { [weak self] (description, error) in
                    if let error = error {
                        fatalError("Couldn't load CoreData Stack \(error.localizedDescription)")
                    }

                    DispatchQueue.main.async {
                        completionHandler(self?.persistentContainer)
                    }
                }
            }
        }
    }

    static func manageObjectModel(with name: String) -> NSManagedObjectModel {
        guard let modelURL = Bundle.main.url(forResource: name, withExtension: "momd") else {
            fatalError("Error could not find model.")
        }

        guard let managedObjectModel = NSManagedObjectModel(contentsOf: modelURL) else {
            fatalError("Error initializing managedObjectModel from: \(modelURL).")
        }

        return managedObjectModel
    }

    func performInBackground(_ block: @escaping (NSManagedObjectContext) -> Void) {
        let privateMOC = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)

        privateMOC.parent = viewContext

        privateMOC.perform {
            block(privateMOC)
        }
    }

    func save() {
        do {
            try persistentContainer.viewContext.save()
        } catch {
            print("=== could not save view context ===")
            print("error: \(error.localizedDescription)")
        }
    }

    func reset() {
        persistentContainer.viewContext.reset()
    }

    func delete() {

        guard let persistentStoreUrl = persistentContainer
                .persistentStoreCoordinator.persistentStores.first?.url else {
            return
        }

        do {
            try persistentContainer.persistentStoreCoordinator.destroyPersistentStore(
                at: persistentStoreUrl,
                ofType: NSSQLiteStoreType,
                options: nil
            )
        } catch {
            fatalError("could not delete test database. \(error.localizedDescription)")
        }
    }
}

extension DataController {

    func saveNotebooks() {
        let managedObjectContext = viewContext
        guard let notebook1 = NotebookMO.createNotebook(
            createdAt: Date(),
            title: "notebook 1",
            in: managedObjectContext
        ) else { return }

        guard let notebook2 = NotebookMO.createNotebook(
            createdAt: Date(),
            title: "notebook 2",
            in: managedObjectContext
        ) else { return }

        guard let notebook3 = NotebookMO.createNotebook(
            createdAt: Date(),
            title: "notebook 3",
            in: managedObjectContext
        ) else { return }

        let notebookImage = UIImage(systemName: "book.closed")
        if let dataNotebookImage = notebookImage?.pngData() {
            notebook1.photograph = PhotographMO.createPhoto(
                imageData: dataNotebookImage,
                managedObjectContext: managedObjectContext
            )
            notebook2.photograph = PhotographMO.createPhoto(
                imageData: dataNotebookImage,
                managedObjectContext: managedObjectContext
            )
            notebook3.photograph = PhotographMO.createPhoto(
                imageData: dataNotebookImage,
                managedObjectContext: managedObjectContext
            )
        }

        NoteMO.createNote(
            managedObjectContext: managedObjectContext,
            notebook: notebook1,
            title: "nota del notebook 1",
            contents: "Contents",
            createdAt: Date()
        )

        NoteMO.createNote(
            managedObjectContext: managedObjectContext,
            notebook: notebook1,
            title: "nota del notebook 1",
            contents: "Contents",
            createdAt: Date()
        )

        NoteMO.createNote(
            managedObjectContext: managedObjectContext,
            notebook: notebook2,
            title: "nota del notebook 2",
            contents: "Contents",
            createdAt: Date()
        )

        NoteMO.createNote(
            managedObjectContext: managedObjectContext,
            notebook: notebook3,
            title: "nota del notebook 3",
            contents: "Contents",
            createdAt: Date()
        )

        do {
            try managedObjectContext.save()
        } catch {
            fatalError("failure to save in background.")
        }
    }

    func saveNotebooksInBackground() {
        performInBackground { (privateManagedObjectContext) in
            let managedObjectContext = privateManagedObjectContext
            guard let notebook = NotebookMO.createNotebook(
                createdAt: Date(),
                title: "notebook nuevo",
                in: managedObjectContext
            ) else { return }

            let notebookImage = UIImage(systemName: "book.closed")
            if let dataNotebookImage = notebookImage?.pngData() {
                notebook.photograph = PhotographMO.createPhoto(
                    imageData: dataNotebookImage,
                    managedObjectContext: managedObjectContext
                )
            }

            do {
                try managedObjectContext.save()
            } catch {
                fatalError("failure to save in background.")
            }
        }
    }

    func addNote(with urlImage: URL, notebook: NotebookMO) {
        performInBackground { (managedObjectContext) in
            guard let imageThumbnail = DownSampler.downsample(imageAt: urlImage),
                  let imageThumbnailData = imageThumbnail.pngData() else {
                return
            }

            let notebookID = notebook.objectID
            let copyNotebook = managedObjectContext.object(with: notebookID) as! NotebookMO

            let photograhMO = PhotographMO.createPhoto(imageData: imageThumbnailData,
                                                       managedObjectContext: managedObjectContext)

            let note = NoteMO.createNote(managedObjectContext: managedObjectContext,
                                         notebook: copyNotebook,
                                         title: "titulo de nota",
                                         contents: "Contents",
                                         createdAt: Date())
            photograhMO?.note = note
            do {
                try managedObjectContext.save()
            } catch {
                fatalError("could not create note with thumbnail image in background.")
            }
        }
    }

    func addPhotograph(with urlImage: URL, note: NoteMO) {
        performInBackground { (managedObjectContext) in
            guard let imageThumbnail = DownSampler.downsample(imageAt: urlImage),
                  let imageThumbnailData = imageThumbnail.pngData() else {
                return
            }

            let noteID = note.objectID
            let copyNote = managedObjectContext.object(with: noteID) as! NoteMO
            let photograh = PhotographMO.createPhoto(imageData: imageThumbnailData,
                                                       managedObjectContext: managedObjectContext)
            photograh?.note = copyNote

            do {
                try managedObjectContext.save()
            } catch {
                fatalError("could not create note with thumbnail image in background.")
            }
        }
    }

    func editNote(note: NoteMO, title: String, content: String) {
        performInBackground { (managedObjectContext) in

            let noteID = note.objectID
            let copyNote = managedObjectContext.object(with: noteID) as! NoteMO
            copyNote.title = title
            copyNote.contents = content

            do {
                try managedObjectContext.save()
            } catch {
                fatalError("could not create note with thumbnail image in background.")
            }
            self.save()
        }
    }
}
