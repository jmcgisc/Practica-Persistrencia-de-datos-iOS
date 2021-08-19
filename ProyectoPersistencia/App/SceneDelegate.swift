//
//  SceneDelegate.swift
//  ProyectoPersistencia
//
//  Created by jose manuel carreiro galicia on 01/8/21.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    var dataController: DataController?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {

        setDataController()
        guard let notebooksViewController = UIStoryboard(
            name: "Notebooks",
            bundle: nil
        ).instantiateViewController(identifier: "NotebooksViewController") as? NotebooksViewController else {
            fatalError("NotebookTableViewController could not be created.")
        }
        notebooksViewController.dataController = dataController

        guard let windowScene = (scene as? UIWindowScene) else { return }
        self.window = UIWindow(windowScene: windowScene)
        self.window?.rootViewController = UINavigationController(rootViewController: notebooksViewController)
        self.window?.makeKeyAndVisible()
    }

    private func setDataController() {
        dataController = DataController(
            modelName: "ProyectoPersistencia",
            optionalStoreName: nil,
            completionHandler: { [weak self] persistentContainer in
                guard persistentContainer != nil else {
                    fatalError("the core data stack was not created")
                }
                self?.preloadData()
            })
    }

    func preloadData() {
        guard !UserDefaults.standard.bool(forKey: "hasPreloadData") else {
            return
        }
        UserDefaults.standard.set(true, forKey: "hasPreloadData")
        dataController?.saveNotebooks()
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.

        // Save changes in the application's managed object context when the application transitions to the background.
        (UIApplication.shared.delegate as? AppDelegate)?.saveContext()
    }


}

