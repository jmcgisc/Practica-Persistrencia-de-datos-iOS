//
//  NotebooksViewController.swift
//  ProyectoPersistencia
//
//  Created by jose manuel carreiro galicia on 01/8/21.
//

import UIKit
import CoreData

class NotebooksViewController: UIViewController {

    @IBOutlet var tableView: UITableView?

    private var deleteDataButton: UIBarButtonItem?
    private var loadDataButton: UIBarButtonItem?

    var dataController: DataController?
    var fetchResultsController: NSFetchedResultsController<NSFetchRequestResult>?

    override func viewDidLoad() {
        title = "Notebooks"
        initializeFetchResultsController()
        setupBarButton()
        setupTableView()
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let segueId = segue.identifier,
           segueId == "noteSegueIdentifier" {
            let destination = segue.destination as! NotesViewController
            let indexPathSelected = tableView?.indexPathForSelectedRow
            let selectedNotebook = fetchResultsController?.object(at: indexPathSelected ?? IndexPath()) as! NotebookMO
            destination.notebook = selectedNotebook
            destination.dataController = dataController
        }
    }

    @objc
    func loadData() {
        dataController?.saveNotebooksInBackground()
    }

    @objc
    func deleteData() {
        dataController?.save()
        dataController?.delete()
        dataController?.reset()
        initializeFetchResultsController()
        tableView?.reloadData()
    }

    private func setupBarButton() {
        loadDataButton = UIBarButtonItem(
            image: UIImage(systemName: "plus"),
            style: .plain,
            target: self,
            action: #selector(loadData)
        )
        deleteDataButton = UIBarButtonItem(
            image: UIImage(systemName: "trash"),
            style: .plain,
            target: self,
            action: #selector(deleteData)
        )
        deleteDataButton?.tintColor = .red
        navigationItem.leftBarButtonItem = loadDataButton
        navigationItem.rightBarButtonItem = deleteDataButton
    }

    private func setupTableView() {
        tableView?.dataSource = self
        tableView?.delegate = self
        tableView?.rowHeight = 100
    }

    private func initializeFetchResultsController() {
        guard let dataController = dataController else { return }
        let viewContext = dataController.viewContext
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Notebook")
        let notebookTitleSortDescriptor = NSSortDescriptor(key: "title",
                                                           ascending: true)
        request.sortDescriptors = [notebookTitleSortDescriptor]

        self.fetchResultsController = NSFetchedResultsController(
            fetchRequest: request,
            managedObjectContext: viewContext,
            sectionNameKeyPath: nil,
            cacheName: nil
        )

        self.fetchResultsController?.delegate = self

        do {
            try self.fetchResultsController?.performFetch()
        } catch {
            print("Error while trying to perform a notebook fetch.")
        }
    }
}

extension NotebooksViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: "noteSegueIdentifier", sender: nil)
    }
}

extension NotebooksViewController: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        return fetchResultsController?.sections?.count ?? 0
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let fetchResultsController = fetchResultsController {
            deleteDataButton?.isEnabled = fetchResultsController.sections![section].numberOfObjects > 0
            return fetchResultsController.sections![section].numberOfObjects
        } else {
            return 0
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "notebookCell",
                                                 for: indexPath)

        guard let notebook = fetchResultsController?.object(at: indexPath) as? NotebookMO else {
            fatalError("Attempt to configure cell without a managed object")
        }
        cell.textLabel?.text = notebook.title
        if let createAt = notebook.createAt {
            cell.detailTextLabel?.textColor = .gray
            cell.detailTextLabel?.text = HelperDateFormatter.textFrom(date: createAt)
        }

        if let photograph = notebook.photograph,
           let imageData = photograph.imageData,
           let image = UIImage(data: imageData) {
            cell.imageView?.image = image
        }
        cell.selectionStyle = .none
        return cell
    }
}

extension NotebooksViewController: NSFetchedResultsControllerDelegate {

    // will change
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
