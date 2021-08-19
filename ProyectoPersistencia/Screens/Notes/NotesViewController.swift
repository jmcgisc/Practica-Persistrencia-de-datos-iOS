//
//  NotesViewController.swift
//  ProyectoPersistencia
//
//  Created by jose manuel carreiro galicia on 02/8/21.
//

import UIKit
import CoreData

class NotesViewController: UIViewController {

    @IBOutlet var tableView: UITableView?
    @IBOutlet var searchView: UISearchBar?
    private let picker = UIImagePickerController()

    var dataController: DataController?
    var fetchResultsController: NSFetchedResultsController<NSFetchRequestResult>?
    var notebook: NotebookMO?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationController()
        initializeFetchResultsController()
        setupTable()
        searchView?.delegate = self
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let segueId = segue.identifier,
           segueId == "noteDetailSegueIdentifier" {
            let destination = segue.destination as! NoteDetailViewController
            let indexPathSelected = tableView?.indexPathForSelectedRow
            let selectedNote = fetchResultsController?.object(at: indexPathSelected ?? IndexPath()) as! NoteMO
            destination.note = selectedNote
            destination.dataController = dataController
        }
    }

    private func setupNavigationController() {
        title = "Notes"
        let addNoteBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "plus"),
            style: .plain,
            target: self,
            action: #selector(openImagePicker)
        )
        navigationItem.rightBarButtonItem = addNoteBarButtonItem
    }

    @objc
    func openImagePicker() {
        picker.delegate = self
        picker.allowsEditing = false

        if  UIImagePickerController.isSourceTypeAvailable(.photoLibrary),
            let availabletypes = UIImagePickerController.availableMediaTypes(for: .photoLibrary) {
            picker.mediaTypes = availabletypes
        }
        present(picker, animated: true, completion: nil)
    }

    func initializeFetchResultsController() {

        guard let dataController = dataController,
              let notebook = notebook else { return }

        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Note")

        let noteCreateAtSortDescriptor = NSSortDescriptor(key: "createAt", ascending: true)
        fetchRequest.sortDescriptors = [noteCreateAtSortDescriptor]

        fetchRequest.predicate = NSPredicate(format: "notebook == %@", notebook)

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

    func filterNotes(title: String) {

        guard let dataController = dataController,
              let notebook = notebook else { return }

        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Note")

        let noteCreateAtSortDescriptor = NSSortDescriptor(key: "createAt", ascending: true)
        fetchRequest.sortDescriptors = [noteCreateAtSortDescriptor]

        fetchRequest.predicate = NSPredicate(
            format: "(title CONTAINS[cd] %@) AND (notebook == %@)",
            title, notebook)

        let managedObjectContext = dataController.viewContext

        fetchResultsController = NSFetchedResultsController(
            fetchRequest: fetchRequest,
            managedObjectContext: managedObjectContext,
            sectionNameKeyPath: nil,
            cacheName: nil
        )

        do {
            try fetchResultsController?.performFetch()
        } catch {
            fatalError("couldn't find notes \(error.localizedDescription) ")
        }
    }

    private func setupTable() {
        tableView?.dataSource = self
        tableView?.delegate = self
        tableView?.rowHeight = UITableView.automaticDimension
    }
}

extension NotesViewController: UIImagePickerControllerDelegate & UINavigationControllerDelegate {
    func imagePickerController(
        _ picker: UIImagePickerController,
        didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]
    ) {
        picker.dismiss(animated: true) { [unowned self] in
            if let urlImage = info[.imageURL] as? URL {
                if let notebook = self.notebook {
                    self.dataController?.addNote(with: urlImage, notebook: notebook)
                }
            }
        }
    }
}

extension NotesViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        print(searchText)
        if (searchText.isEmpty) {
            initializeFetchResultsController()
        } else {
            filterNotes(title: searchText)
        }
        tableView?.reloadData()
    }
}

extension NotesViewController: UITableViewDataSource, UITableViewDelegate {

    func numberOfSections(in tableView: UITableView) -> Int {
        return fetchResultsController?.sections?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let fetchResultsController = fetchResultsController {
            return fetchResultsController.sections![section].numberOfObjects
        } else {
            return 0
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "noteCell",
                                                 for: indexPath)
        guard let note = fetchResultsController?.object(at: indexPath) as? NoteMO else {
            fatalError("Attempt to configure cell without a managed object")
        }
        cell.textLabel?.text = note.title
        cell.detailTextLabel?.text = note.contents
        cell.detailTextLabel?.textColor = .gray

        if note.photograph?.allObjects.count ?? 0 > 0,
           let photograph = note.photograph?.allObjects[0] as? PhotographMO,
           let imageData = photograph.imageData,
           let image = UIImage(data: imageData) {
            cell.imageView?.image = image
        } else {
            cell.imageView?.image = nil
        }
        cell.selectionStyle = .none
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: "noteDetailSegueIdentifier", sender: nil)
    }
}

extension NotesViewController: NSFetchedResultsControllerDelegate {

    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView?.beginUpdates()
    }

    // did change a section.
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        switch type {
            case .insert:
                tableView?.insertSections(IndexSet(integer: sectionIndex), with: .fade)
            case .delete:
                tableView?.deleteSections(IndexSet(integer: sectionIndex), with: .fade)
            case .move, .update:
                break
            @unknown default: fatalError()
        }
    }

    // did change an object.
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
            case .insert:
                tableView?.insertRows(at: [newIndexPath!], with: .fade)
            case .delete:
                tableView?.deleteRows(at: [indexPath!], with: .fade)
            case .update:
                tableView?.reloadRows(at: [indexPath!], with: .fade)
            case .move:
                tableView?.moveRow(at: indexPath!, to: newIndexPath!)
            @unknown default:
                fatalError()
        }
    }

    // did change content.
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView?.endUpdates()
    }
}
