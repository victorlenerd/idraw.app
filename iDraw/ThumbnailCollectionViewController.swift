/*
See LICENSE folder for this sample’s licensing information.

Abstract:
`ThumbnailCollectionViewController` shows a set of thumbnails of all drawings.
*/

import UIKit
import PencilKit
import CoreData


class ThumbnailCollectionViewController: UICollectionViewController {
    
    var managedObjContext: NSManagedObjectContext?
    var notes: [Note] = []
    // MARK:- View Life Cycle
    
    /// Set up the view initially.
    override func viewDidLoad() {
        super.viewDidLoad()
        
        managedObjContext = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    
        let fetchRequest: NSFetchRequest<Note> = Note.fetchRequest()
        
        do {
           let notes = try? managedObjContext!.fetch(fetchRequest)
            print(notes)
        } catch {
            fatalError("Failed to fetch notes " + error.localizedDescription)
        }

        
        // TODO: - Inform the data model of the current thumbnail traits.
        
        // TODO: - Observe changes to the data model.
    }
    
    /// Inform the data model of the current thumbnail traits.
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
//        dataModelController.thumbnailTraitCollection = traitCollection
    }
    
    // MARK: Data Model Observer
    
    func dataModelChanged() {
        collectionView.reloadData()
    }
    
    // MARK:- Actions
    
    /// Action method: Create a new drawing.
    @IBAction func newDrawing(_ sender: Any) {
        // TODO: Create New Reading Note
    }
    
    // MARK:- Collection View Data Source
    
    /// Data source method: Number of sections.
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    /// Data source method: Number of items in each section.
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.notes.count
    }
    
    /// Data source method: The view for each cell.
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        // Get a cell view with the correct identifier.
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: "ThumbnailCell",
            for: indexPath) as? ThumbnailCollectionViewCell
            else {
                fatalError("Unexpected cell type.")
        }
        
        
        if let index = indexPath.last, index < self.notes.count {
            let note = self.notes[index]
            cell.imageView.image = self.notes[index].drawing?.image(from: CGSize(width: note.canvasWidth, height: note.canvasWidth), scale: 1.0)
        }
        
        return cell
    }
    
    // MARK:- Collection View Delegate
    
    /// Delegate method: Display the drawing for a cell that was tapped.
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        // TODO: Open drawring controller
        
//        // Create the drawing.
//        guard let drawingViewController = storyboard?.instantiateViewController(withIdentifier: "DrawingViewController") as? DrawingViewController,
//            let navigationController = navigationController else {
//                return
//        }
//
//        // Transition to the drawing view controller.
//        drawingViewController.dataModelController = dataModelController
//        drawingViewController.drawingIndex = indexPath.last!
//        navigationController.pushViewController(drawingViewController, animated: true)
    }
}
