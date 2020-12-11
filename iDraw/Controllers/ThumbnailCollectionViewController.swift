/*
See LICENSE folder for this sample’s licensing information.

Abstract:
`ThumbnailCollectionViewController` shows a set of thumbnails of all drawings.
*/

import UIKit
import PencilKit
import CoreData

enum Section {
  case main
}

typealias DataSource = UICollectionViewDiffableDataSource<Section, Note>

class ThumbnailCollectionViewController: UICollectionViewController {
    
    /// The width used for drawing canvases.
    var dataController: DataController!
        
    var collectionViewDataSource: UICollectionViewDiffableDataSource<Section, Note>!
    var diffableDataSourceSnapshot: NSDiffableDataSourceSnapshot<Section, Note>!
    var fetchResultsController: NSFetchedResultsController<Note>!
    var notes: [Note] = []
    // MARK:- View Life Cycle
    
    /// Set up the view initially.
    override func viewDidLoad() {
        super.viewDidLoad()
        dataController =  (UIApplication.shared.delegate as! AppDelegate).dataController

    
        let fetchRequest: NSFetchRequest<Note> = Note.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "dateModified", ascending: true)]
        
        fetchResultsController = NSFetchedResultsController(
            fetchRequest: fetchRequest,
            managedObjectContext: dataController.viewContext,
            sectionNameKeyPath: nil,
            cacheName: "notes"
        )
        
        fetchResultsController.delegate = self
        try? fetchResultsController.performFetch()
        
        updateDataSnapshot()
        
        collectionViewDataSource = UICollectionViewDiffableDataSource(collectionView: collectionView) { (collectionView, indexPath, note) -> UICollectionViewCell? in
            
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ThumbnailCell", for: indexPath) as! ThumbnailCollectionViewCell
    
            if let data = note.drawing {
                let drawing = try? PKDrawing(data: data)
                cell.imageView.image = drawing?.image(from: CGRect(x: 0, y: 0, width: note.canvasWidth, height: note.canvasWidth), scale: 1.0)
            }
            
            return cell
        }
        
        collectionViewDataSource.apply(diffableDataSourceSnapshot)
        collectionView.dataSource = collectionViewDataSource
    }
    
    func updateDataSnapshot() {
        diffableDataSourceSnapshot = NSDiffableDataSourceSnapshot<Section, Note>()
        diffableDataSourceSnapshot.appendSections([.main])
        diffableDataSourceSnapshot.appendItems(fetchResultsController.fetchedObjects ?? [])
    }
    
    /// Inform the data model of the current thumbnail traits.
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        print("trait changed")
//        dataModelController.thumbnailTraitCollection = traitCollection
    }
    
    // MARK:- Actions
    
    /// Action method: Create a new drawing.
    @IBAction func newDrawing(_ sender: Any) {
        let newDrawing = PKDrawing()
        let defaultNote = Note(context: dataController.viewContext)
        
        defaultNote.uuid = UUID()
        defaultNote.dateModified = Date()
        defaultNote.drawing = newDrawing.dataRepresentation()
        defaultNote.canvasWidth = Double(dataController.canvasWidth)
        
        dataController.saveViewContext()
    }
        
    // MARK:- Collection View Delegate
    
    /// Delegate method: Display the drawing for a cell that was tapped.
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let drawingViewController = storyboard?.instantiateViewController(withIdentifier: "DrawingViewController") as? DrawingViewController,
            let navigationController = navigationController else {
                return
        }
        
        drawingViewController.dataController = dataController
        drawingViewController.note = self.fetchResultsController.fetchedObjects?[indexPath.item]
        navigationController.pushViewController(drawingViewController, animated: true)
    }
}

extension ThumbnailCollectionViewController: NSFetchedResultsControllerDelegate {
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        
        if let notes = fetchResultsController.fetchedObjects {
            switch (type) {
            case .insert:
                diffableDataSourceSnapshot.appendItems([notes[newIndexPath!.item]])
                break
            case .delete:
                diffableDataSourceSnapshot.deleteItems([notes[indexPath!.item]])
                break
            case .update:
                diffableDataSourceSnapshot.reloadSections([.main])
                break
            case .move:
                break
            default:
                break
            }
        }
        
        collectionViewDataSource.apply(diffableDataSourceSnapshot)
    }
    
    private func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChangeContentWith snapshot: NSDiffableDataSourceSnapshot<Section, Note>) {
        
        print("eeeee")
        
        guard let dataSource = collectionView?.dataSource as? UICollectionViewDiffableDataSource<Section, Note> else {
             fatalError("The data source has not implemented snapshot support while it should")
         }
        
        dataSource.apply(snapshot, animatingDifferences: true)
    }
    
}
