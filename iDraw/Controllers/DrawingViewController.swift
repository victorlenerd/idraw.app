/*
See LICENSE folder for this sample’s licensing information.

Abstract:
`DrawingViewController` is the primary view controller for showing drawings.
*/

///`PKCanvasView` is the main drawing view that you will add to your view hierarchy.
/// The drawingPolicy dictates whether drawing with a finger is allowed.  If it's set to default and if the tool picker is visible,
/// then it will respect the global finger pencil toggle in Settings or as set in the tool picker.  Otherwise, only drawing with
/// a pencil is allowed.

/// You can add your own class as a delegate of PKCanvasView to receive notifications after a user
/// has drawn or the drawing was updated. You can also set the tool or toggle the ruler on the canvas.

/// There is a shared tool picker for each window. The tool picker floats above everything, similar
/// to the keyboard. The tool picker is moveable in a regular size class window, and fixed to the bottom
/// in compact size class. To listen to tool picker notifications, add yourself as an observer.

/// Tool picker visibility is based on first responders. To make the tool picker appear, you need to
/// associate the tool picker with a `UIResponder` object, such as a view, by invoking the method
/// `UIToolpicker.setVisible(_:forResponder:)`, and then by making that responder become the first

/// Best practices:
///
/// -- Because the tool picker palette is floating and moveable for regular size classes, but fixed to the
/// bottom in compact size classes, make sure to listen to the tool picker's obscured frame and adjust your UI accordingly.

/// -- For regular size classes, the palette has undo and redo buttons, but not for compact size classes.
/// Make sure to provide your own undo and redo buttons when in a compact size class.

import UIKit
import PencilKit
import CoreData


class DrawingViewController: UIViewController {
    
    @IBOutlet weak var canvasView: PKCanvasView!
    @IBOutlet var undoBarButtonitem: UIBarButtonItem!
    @IBOutlet var redoBarButtonItem: UIBarButtonItem!
    
    var toolPicker: PKToolPicker!

    /// On iOS 14.0, this is no longer necessary as the finger vs pencil toggle is a global setting in the toolpicker
    var pencilFingerBarButtonItem: UIBarButtonItem!
    
    var dataController: DataController!
    
    /// Standard amount of overscroll allowed in the canvas.
    static let canvasOverscrollHeight: CGFloat = 500
    var note: Note!
    
    // MARK: View Life Cycle
    
    /// Set up the drawing initially.
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Set up the canvas view with the first drawing from the data model.
        canvasView.drawing = try! PKDrawing(data: note.drawing!)
        canvasView.delegate = self
        canvasView.alwaysBounceVertical = true
        
        // Set up the tool picker
        if #available(iOS 14.0, *) {
            toolPicker = PKToolPicker()
        } else {
            // Set up the tool picker, using the window of our parent because our view has not
            // been added to a window yet.
            let window = parent?.view.window
            toolPicker = PKToolPicker.shared(for: window!)
        }
        
        toolPicker.setVisible(true, forFirstResponder: canvasView)
        toolPicker.addObserver(canvasView)
        toolPicker.addObserver(self)
        updateLayout(for: toolPicker)
        canvasView.becomeFirstResponder()
        
        // Before iOS 14, add a button to toggle finger drawing.
        if #available(iOS 14.0, *) { } else {
            pencilFingerBarButtonItem = UIBarButtonItem(title: "Enable Finger Drawing",
                                                        style: .plain,
                                                        target: self,
                                                        action: #selector(toggleFingerPencilDrawing(_:)))
            navigationItem.rightBarButtonItems?.append(pencilFingerBarButtonItem)
            canvasView.allowsFingerDrawing = false
        }
        
        // Always show a back button.
        navigationItem.leftItemsSupplementBackButton = true
        
        // Set this view controller as the delegate for creating full screenshots.
        parent?.view.window?.windowScene?.screenshotService?.delegate = self
    }
    
    /// When the view is resized, adjust the canvas scale so that it is zoomed to the default `canvasWidth`.
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        let canvasScale = canvasView.bounds.width / CGFloat(768)
        canvasView.minimumZoomScale = canvasScale
        canvasView.maximumZoomScale = canvasScale
        canvasView.zoomScale = canvasScale
        
        // Scroll to the top.
        updateContentSizeForDrawing()
        canvasView.contentOffset = CGPoint(x: 0, y: -canvasView.adjustedContentInset.top)
    }
    
    /// When the view is removed, save the modified drawing, if any.
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // Remove this view controller as the screenshot delegate.
        view.window?.windowScene?.screenshotService?.delegate = nil
    }
    
    /// Hide the home indicator, as it will affect latency.
    override var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }
    
    // MARK: Actions
    
    /// Action method: Turn finger drawing on or off, but only on devices before iOS 14.0
    @IBAction func toggleFingerPencilDrawing(_ sender: Any) {
        if #available(iOS 14.0, *) { } else {
            canvasView.allowsFingerDrawing.toggle()
            let title = canvasView.allowsFingerDrawing ? "Disable Finger Drawing" : "Enable Finger Drawing"
            pencilFingerBarButtonItem.title = title
        }
    }
    
    /// Helper method to set a new drawing, with an undo action to go back to the old one.
    func setNewDrawingUndoable(_ newDrawing: PKDrawing) {
        let oldDrawing = canvasView.drawing
        undoManager?.registerUndo(withTarget: self) {
            $0.setNewDrawingUndoable(oldDrawing)
        }
        
        canvasView.drawing = newDrawing
    }
    
    /// Helper method to set a suitable content size for the canvas view.
    func updateContentSizeForDrawing() {
        // Update the content size to match the drawing.
        let drawing = canvasView.drawing
        let contentHeight: CGFloat
        
        // Adjust the content size to always be bigger than the drawing height.
        if !drawing.bounds.isNull {
            contentHeight = max(canvasView.bounds.height, (drawing.bounds.maxY + DrawingViewController.canvasOverscrollHeight) * canvasView.zoomScale)
        } else {
            contentHeight = canvasView.bounds.height
        }
        canvasView.contentSize = CGSize(width: CGFloat(note.canvasWidth) * canvasView.zoomScale, height: contentHeight)
    }
    
    func uplaodImage() {
        let drawing = canvasView.drawing
        
        let stagingURL = URL(string: "https://idraw-app.df.r.appspot.com//upload/test-note-uuid")!
        
        var urlRequest = URLRequest(url: stagingURL)
        
        urlRequest.httpMethod = "POST"
        
        let boundaryConstant = "----------------12345";
        let contentType = "multipart/form-data;boundary=" + boundaryConstant
        
        urlRequest.setValue(contentType, forHTTPHeaderField: "Content-Type")
        
        var uploadData = Data()
        
        uploadData.append("\r\n--\(boundaryConstant)\r\n".data(using: String.Encoding.utf8)!)
        uploadData.append("Content-Disposition: form-data; name=\"image\"; filename=\"file.png\"\r\n".data(using: String.Encoding.utf8)!)
        uploadData.append("Content-Type: image/png\r\n\r\n".data(using: String.Encoding.utf8)!)
        uploadData.append(drawing.image(from: canvasView.frame, scale: 1.0).pngData()!)
        uploadData.append("\r\n--\(boundaryConstant)--\r\n".data(using: String.Encoding.utf8)!)
        
        urlRequest.httpBody = uploadData
        
        URLSession.shared.dataTask(with: urlRequest) { (data: Data?, urlResponse, error: Error?) in
            if let err = error {
                print("FAILED TO UPDLOAD: \(err.localizedDescription)")
                return
            }
            
            print("Status:: \((urlResponse as? HTTPURLResponse)?.statusCode)")
        }.resume()

    }

}



// MARK:- Canvas View Delegate

extension DrawingViewController: PKCanvasViewDelegate {

    /// Delegate method: Note that the drawing has changed.
    func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
        note.drawing = canvasView.drawing.dataRepresentation()
        dataController.saveViewContext()
    }
    
}

// MARK:- Tool Picker Observer

extension DrawingViewController: PKToolPickerObserver {

    /// Delegate method: Note that the tool picker has changed which part of the canvas view
    /// it obscures, if any.
    func toolPickerFramesObscuredDidChange(_ toolPicker: PKToolPicker) {
        updateLayout(for: toolPicker)
    }
    
    /// Delegate method: Note that the tool picker has become visible or hidden.
    func toolPickerVisibilityDidChange(_ toolPicker: PKToolPicker) {
        updateLayout(for: toolPicker)
    }
    
    /// Helper method to adjust the canvas view size when the tool picker changes which part
    /// of the canvas view it obscures, if any.
    ///
    /// Note that the tool picker floats over the canvas in regular size classes, but docks to
    /// the canvas in compact size classes, occupying a part of the screen that the canvas
    /// could otherwise use.
    func updateLayout(for toolPicker: PKToolPicker) {
        let obscuredFrame = toolPicker.frameObscured(in: view)
        
        // If the tool picker is floating over the canvas, it also contains
        // undo and redo buttons.
        if obscuredFrame.isNull {
            canvasView.contentInset = .zero
            navigationItem.leftBarButtonItems = []
        }
        
        // Otherwise, the bottom of the canvas should be inset to the top of the
        // tool picker, and the tool picker no longer displays its own undo and
        // redo buttons.
        else {
            canvasView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: view.bounds.maxY - obscuredFrame.minY, right: 0)
            navigationItem.leftBarButtonItems = [undoBarButtonitem, redoBarButtonItem]
        }
        canvasView.scrollIndicatorInsets = canvasView.contentInset
    }
    
}



// MARK:- Screenshot Service Delegate

extension DrawingViewController: UIScreenshotServiceDelegate {
    
    /// Delegate method: Generate a screenshot as a PDF.
    func screenshotService(
        _ screenshotService: UIScreenshotService,
        generatePDFRepresentationWithCompletion completion:
        @escaping (_ PDFData: Data?, _ indexOfCurrentPage: Int, _ rectInCurrentPage: CGRect) -> Void) {
        
        // Find out which part of the drawing is actually visible.
        let drawing = canvasView.drawing
        let visibleRect = canvasView.bounds
        
        // Convert to PDF coordinates, with (0, 0) at the bottom left hand corner,
        // making the height a bit bigger than the current drawing.
        let pdfWidth = CGFloat(note.canvasWidth)
        let pdfHeight = drawing.bounds.maxY + 100
        let canvasContentSize = canvasView.contentSize.height - DrawingViewController.canvasOverscrollHeight
        
        let xOffsetInPDF = pdfWidth - (pdfWidth * visibleRect.minX / canvasView.contentSize.width)
        let yOffsetInPDF = pdfHeight - (pdfHeight * visibleRect.maxY / canvasContentSize)
        let rectWidthInPDF = pdfWidth * visibleRect.width / canvasView.contentSize.width
        let rectHeightInPDF = pdfHeight * visibleRect.height / canvasContentSize
        
        let visibleRectInPDF = CGRect(
            x: xOffsetInPDF,
            y: yOffsetInPDF,
            width: rectWidthInPDF,
            height: rectHeightInPDF)
        
        // Generate the PDF on a background thread.
        DispatchQueue.global(qos: .background).async {
            
            // Generate a PDF.
            let bounds = CGRect(x: 0, y: 0, width: pdfWidth, height: pdfHeight)
            let mutableData = NSMutableData()
            UIGraphicsBeginPDFContextToData(mutableData, bounds, nil)
            UIGraphicsBeginPDFPage()
            
            // Generate images in the PDF, strip by strip.
            var yOrigin: CGFloat = 0
            let imageHeight: CGFloat = 1024
            while yOrigin < bounds.maxY {
                let imgBounds = CGRect(x: 0, y: yOrigin, width: CGFloat(self.note.canvasWidth), height: min(imageHeight, bounds.maxY - yOrigin))
                let img = drawing.image(from: imgBounds, scale: 2)
                img.draw(in: imgBounds)
                yOrigin += imageHeight
            }
            
            UIGraphicsEndPDFContext()
            
            // Invoke the completion handler with the generated PDF data.
            completion(mutableData as Data, 0, visibleRectInPDF)
        }
    }
    
}
