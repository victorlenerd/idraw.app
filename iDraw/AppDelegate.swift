/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The application delegate maintains the app's life cycle.
*/

/// iDraw is a drawing app that demonstrates how to use the PencilKit framework.

/// It shows how you can use PKCanvasView and PKDrawing classes for a great pencil drawing experience,
/// featuring a thumbnail viewer, a drawing canvas with the system tool picker, and a signature pane popover.

/// While PencilKit is optimized for the pencil drawing experience, it also allows users to draw with a finger.

import UIKit
import CoreData
import PencilKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    
    let dataController = DataController()
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        if UserDefaults.standard.bool(forKey: "isFirstLaunch") == false {
            
            if let data = NSDataAsset(name: "Notes")?.data {
                let defaultNote = Note(context: dataController.viewContext)
                defaultNote.uuid = UUID()
                defaultNote.drawing = data
                defaultNote.canvasWidth = Double(dataController.canvasWidth)
            }

            dataController.saveViewContext()

            UserDefaults.standard.set(true, forKey: "isFirstLaunch")
        }
        
        return true
    }
        
}

