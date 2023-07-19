//
//  ViewController.swift
//  ColoredPointCloud
//
//  Created by hvrl_mt on 2022/04/25.
//

import UIKit
import MetalKit
import ARKit

class ViewController: UIViewController {
    
    let session = ARSession()
    var renderer: Renderer!
    
    static let fileManager = FileManager.default
    static var rootDirectory: URL!
    static var isRecording = false
    static var showPointCloud = false
    
    var totalFrames = 0 {
        didSet {
            updateLog()
        }
    }
    var savedFrames = 0{
        didSet {
            updateLog()
        }
    }
    
    @IBOutlet weak var depthImageView: UIImageView!
    @IBOutlet weak var recordButton: UIButton!
    @IBOutlet weak var logTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let metalView = view as? MTKView else {
            fatalError("metal view not set up in storyboard")
        }
        
        let directoryID = determineDirectoryID()
        ViewController.rootDirectory = getRootDirectory(directoryID: -1)
        renderer = Renderer(metalView: metalView, session: session, depthImageView: depthImageView, directoryID: directoryID)
        renderer.delegate = self
        renderer.capturedImage.delegate = self
        renderer.depthImage.delegate = self
        Renderer.drawRectResized(size: metalView.drawableSize)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
//        configuration.sceneReconstruction = .mesh
        configuration.frameSemantics = .sceneDepth
        
        // Run the view's session
        session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        session.pause()
    }
    
    
    // Fix the portrait position
    override var shouldAutorotate: Bool {
        return false
    }
    
    // Enable only the portrait position
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        ViewController.isRecording = !ViewController.isRecording
        let text = ViewController.isRecording ? "Stop" : "Record"
        recordButton.setTitle(text, for: .normal)
        toast("Saving has been paused due to low memory", self.view)
    }
    
    
    @IBAction func renderModeSegmentedControlTapped(_ sender: UISegmentedControl) {
        guard let renderer = renderer else {
            return
        }
        
        depthImageView.image = nil
        
        switch sender.selectedSegmentIndex {
        case 0:
            renderer.renderMode = .cameraImage
        case 1:
            renderer.renderMode = .depthMap
        case 2:
            renderer.renderMode = .confidenceMap
        default:
            renderer.renderMode = .cameraImage
        }
    }
    
    
    @IBAction func saveButtonTapped(_ sender: UIButton) {
        let particle = renderer.particle
        
        var fileToWrite = ""
        
        let startPointer = particle.uniformBuffer.contents()
        var pointCount = 0
        
        for index in 0..<particle.currentPointCount {
            let offset = MemoryLayout<ParticleUniforms>.stride * index
            let pointer = startPointer.advanced(by: offset)
            let point = pointer.assumingMemoryBound(to: ParticleUniforms.self).pointee
            
            if point.confidence < 2.0 {
                continue
            }
            pointCount += 1
            
            let position = point.position
            let colors = point.color

            let red = adjustColor(color: colors.x)
            let green = adjustColor(color: colors.y)
            let blue = adjustColor(color: colors.z)

            let pvValue = "\(position.x) \(position.y) \(position.z) \(red) \(green) \(blue) 255\r\n"
            fileToWrite += pvValue
        }
        
        let headers = ["ply",
                       "format ascii 1.0",
                       "element vertex \(pointCount)",
                       "property float x",
                       "property float y",
                       "property float z",
                       "property uchar red",
                       "property uchar green",
                       "property uchar blue",
                       "property uchar alpha",
                       "element face 0",
                       "property list uchar int vertex_indices",
                       "end_header"]
        
        var headerString = ""
        for header in headers {
            headerString += header + "\r\n"
        }
        fileToWrite = headerString + fileToWrite
        
        let urlPLY = ViewController.rootDirectory.appendingPathComponent("point_cloud").appendingPathExtension("ply")
        
        do {
            try fileToWrite.write(to: urlPLY, atomically: true, encoding: String.Encoding.ascii)

//            let activityItems = [urlPLY]
//            let activityController = UIActivityViewController(activityItems: activityItems,
//                                                              applicationActivities: nil)
//            activityController.popoverPresentationController?.sourceView = sender
//            self.present(activityController, animated: true, completion: nil)

        } catch {
            fatalError(error.localizedDescription)
        }
    }
    
    func adjustColor(color: simd_float1) -> Int {
        let intColor = Int(color * 255.0)
        
        if intColor > 255 {
            return 255
        } else if intColor < 0 {
            return 0
        } else {
            return intColor
        }
    }
    
    
    @IBAction func toggleSaveButton(_ sender: UIButton) {
        let directoryID = determineDirectoryID()
        ViewController.rootDirectory = getRootDirectory(directoryID: directoryID)
        
        let message = ViewController.isRecording ? "End Saving \(directoryID - 1)" : "Start Saving \(directoryID)"
        toast(message, self.view)
        
        ViewController.isRecording = !ViewController.isRecording
        let text = ViewController.isRecording ? "Stop" : "Record"
        sender.setTitle(text, for: .normal)
        
        if ViewController.isRecording {
            createSaveDirectory(directoryName: "RGB")
            createSaveDirectory(directoryName: "Frame")
            createSaveDirectory(directoryName: "Confidence")
            totalFrames = 0
            savedFrames = 0
        }
    }
    
    
    @IBAction func visualizationSwitchTapped(_ sender: UISwitch) {
        ViewController.showPointCloud = !ViewController.showPointCloud
    }
}


// MARK: - StatusLogDelegate

extension ViewController: StatusLogDelegate {
    func incrementTotalFrames() {
        totalFrames += 1
    }
    
    func incrementSavedFrames() {
        savedFrames += 1
    }

    func updateLog() {
        let text = "Frames saved \(savedFrames)/\(totalFrames)"
        DispatchQueue.main.async {
            self.logTextField.text = text
        }
    }
}
