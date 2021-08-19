//
//  NoteDetailViewController.swift
//  ProyectoPersistencia
//
//  Created by jose manuel carreiro galicia on 03/8/21.
//

import UIKit
import CoreData

class NoteDetailViewController: UIViewController {

    var blockOperations: [BlockOperation] = []

    @IBOutlet var titleNote: UITextField?
    @IBOutlet var contentNote: UITextView?
    @IBOutlet var imageCollection: UICollectionView?
    private let collectionLayout = UICollectionViewFlowLayout()
    private let picker = UIImagePickerController()

    var dataController: DataController?
    var fetchResultsController: NSFetchedResultsController<NSFetchRequestResult>?
    var note: NoteMO?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupNoteDetails()
        initializeFetchResultsController()
        setupTable()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        print("desaparezco")
        guard let dataController = dataController,
              let note = note else { return }
        guard let titleNote = titleNote?.text else { return }
        guard let contentNote = contentNote?.text else { return }
        dataController.editNote(note: note, title: titleNote, content: contentNote)
    }

    deinit {
        for o in blockOperations { o.cancel() }
        blockOperations.removeAll()
    }

    func initializeFetchResultsController() {

        guard let dataController = dataController,
              let note = note else { return }

        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Photograph")
        let photoCreateAtSortDescriptor = NSSortDescriptor(key: "createAt", ascending: false)
        fetchRequest.sortDescriptors = [photoCreateAtSortDescriptor]
        fetchRequest.predicate = NSPredicate(format: "note == %@", note)
        let managedObjectContext = dataController.viewContext

        fetchResultsController = NSFetchedResultsController(
            fetchRequest: fetchRequest,
            managedObjectContext: managedObjectContext,
            sectionNameKeyPath: nil,
            cacheName: nil
        )

        fetchResultsController?.delegate = self

        do {
            try fetchResultsController?.performFetch()
        } catch {
            fatalError("couldn't find notes \(error.localizedDescription) ")
        }
    }


    private func setupNoteDetails() {
        title = "Details"
        guard note != nil else { return }
        titleNote?.text = note?.title
        contentNote?.text = note?.contents
    }

    private func setupTable() {
        collectionLayout.scrollDirection = .vertical
        imageCollection?.collectionViewLayout = collectionLayout
        imageCollection?.dataSource = self
        imageCollection?.delegate = self
    }

    @IBAction func addPhoto(_ sender: UIButton) {
        picker.delegate = self
        picker.allowsEditing = false

        if  UIImagePickerController.isSourceTypeAvailable(.photoLibrary),
            let availabletypes = UIImagePickerController.availableMediaTypes(for: .photoLibrary) {
            picker.mediaTypes = availabletypes
        }
        present(picker, animated: true, completion: nil)
    }
}

private struct Constants {
    static let numberOfCellsPerRow: CGFloat = 3
    static let rowSpacing: CGFloat = 8
}

extension NoteDetailViewController: UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let yourWidth = (collectionView.bounds.width/Constants.numberOfCellsPerRow) - Constants.rowSpacing
        let yourHeight = yourWidth
        return CGSize(width: yourWidth, height: yourHeight)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return Constants.rowSpacing
    }
}

extension NoteDetailViewController:
    UIImagePickerControllerDelegate & UINavigationControllerDelegate {
    func imagePickerController(
        _ picker: UIImagePickerController,
        didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true) { [unowned self] in
            if let urlImage = info[.imageURL] as? URL {
                if let note = self.note {
                    self.dataController?.addPhotograph(with: urlImage, note: note)
                }
            }
        }
    }
}

extension NoteDetailViewController: UICollectionViewDataSource {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if let fetchResultsController = fetchResultsController {
            return fetchResultsController.sections![section].numberOfObjects
        } else {
            return 0
        }
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = imageCollection?.dequeueReusableCell(
            withReuseIdentifier: "photoCell",
            for: indexPath
        ) as? PhotoCell
        guard let photograph = fetchResultsController?.object(at: indexPath) as? PhotographMO else {
            fatalError("Attempt to configure cell without a managed object")
        }

        if let imageData = photograph.imageData,
           let image = UIImage(data: imageData) {
            cell?.configureViews(image: image)
        } else {
            cell?.configureViews(image: nil)
        }
        return cell ?? UICollectionViewCell()
    }
}

extension NoteDetailViewController: NSFetchedResultsControllerDelegate {

    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        blockOperations.removeAll(keepingCapacity: false)
    }

    // did change a section.
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        switch type {
            case .insert:
                blockOperations.append(
                    BlockOperation(block: { [weak self] in
                        if let this = self {
                            this.imageCollection?.insertSections(NSIndexSet(index: sectionIndex) as IndexSet)
                        }
                    })
                )
            case .delete:
                blockOperations.append(
                    BlockOperation(block: { [weak self] in
                        if let this = self {
                            this.imageCollection?.deleteSections(NSIndexSet(index: sectionIndex) as IndexSet)
                        }
                    })
                )
            //imageCollection?.deleteSections(IndexSet(integer: sectionIndex))
            case .move, .update:
                blockOperations.append(
                    BlockOperation(block: { [weak self] in
                        if let this = self {
                            this.imageCollection?.reloadSections(NSIndexSet(index: sectionIndex) as IndexSet)
                        }
                    })
                )
            @unknown default: fatalError()
        }
    }

    // did change an object.
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {

        switch type {
            case .insert:
                blockOperations.append(
                    BlockOperation(block: { [weak self] in
                        if let this = self {
                            this.imageCollection?.insertItems(at: [newIndexPath!])
                        }
                    })
                )
            case .delete:
                blockOperations.append(
                    BlockOperation(block: { [weak self] in
                        if let this = self {
                            this.imageCollection?.deleteItems(at: [indexPath!])
                        }
                    })
                )
            case .update:
                blockOperations.append(
                    BlockOperation(block: { [weak self] in
                        if let this = self {
                            this.imageCollection?.reloadItems(at: [indexPath!])
                        }
                    })
                )
            case .move:
                blockOperations.append(
                    BlockOperation(block: { [weak self] in
                        if let this = self {
                            this.imageCollection?.moveItem(at: indexPath!, to: newIndexPath!)
                        }
                    })
                )
            @unknown default:
                fatalError()
        }
    }

    // did change content.
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        imageCollection?.performBatchUpdates({ () -> Void in
            for operation: BlockOperation in self.blockOperations {
                operation.start()
            }
        }, completion: { (finished) -> Void in
            self.blockOperations.removeAll(keepingCapacity: false)
        })
    }
}
