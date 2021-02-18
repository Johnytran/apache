//
//  ViewController.swift
//  apache
//
//  Created by Owner on 10/2/21.
//

import SceneKit
import ARKit
import Vision

class ViewController: UIViewController, ARSCNViewDelegate, ARSessionDelegate {
    
    
    @IBOutlet weak var arView: ARSCNView!
    var sceneController = MainScene()
    let currentMLModel = FistClassifier364().model;
    private let serialQueue = DispatchQueue(label: "com.aboveground.dispatchqueueml")
    private var visionRequests = [VNRequest]()
    private var timer = Timer()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Set the view's delegate
        self.arView.delegate = self;
        // Allow user to manipulate camera
        arView.allowsCameraControl = true
        // Allow user translate image
        arView.cameraControlConfiguration.allowsTranslation = false

        // Create a new scene
        if let scene = sceneController.scene {

          // Set the scene to the view
            arView.scene = scene;
        }

        
        let position = SCNVector3(0, 0, -8)
        sceneController.addApache(parent: arView.scene.rootNode, position: position)
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()

        // Run the view's session
        arView.session.run(configuration);
        
        
        setupCoreML();

        timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(self.loopCoreMLUpdate), userInfo: nil, repeats: true)
    }
    
    private func setupCoreML() {
        
        guard let selectedModel = try? VNCoreMLModel(for: currentMLModel) else {
            fatalError("Could not load model.")
        }
        
        let classificationRequest = VNCoreMLRequest(model: selectedModel,
                                                    completionHandler: classificationCompleteHandler)
        classificationRequest.imageCropAndScaleOption = VNImageCropAndScaleOption.centerCrop // Crop from centre of images and scale to appropriate size.
        visionRequests = [classificationRequest]
    }
    
    private func classificationCompleteHandler(request: VNRequest, error: Error?) {
            if error != nil {
                print("Error: " + (error?.localizedDescription)!)
                return
            }
            guard let observations = request.results else {
                return
            }
            
            let classifications = observations[0...2]
                .compactMap({ $0 as? VNClassificationObservation })
                .map({ "\($0.identifier) \(String(format:" : %.2f", $0.confidence))" })
                .joined(separator: "\n")
            
            print("Classifications: \(classifications)")
            
            DispatchQueue.main.async {
                let topPrediction = classifications.components(separatedBy: "\n")[0]
                let topPredictionName = topPrediction.components(separatedBy: ":")[0].trimmingCharacters(in: .whitespaces)
                guard let topPredictionScore: Float = Float(topPrediction.components(separatedBy: ":")[1].trimmingCharacters(in: .whitespaces)) else { return }
                
                if (topPredictionScore > 0.95) {
                    print("Top prediction: \(topPredictionName) - score: \(String(describing: topPredictionScore))")
                    guard let childNode = self.arView.scene.rootNode.childNode(withName: "Apache", recursively: true), let apache = childNode as? Apache else { return }

                    if topPredictionName == "fist" {
                        print("fist");
                        apache.animate()
                    }
                    
                    if topPredictionName == "open_hand" || topPredictionName == "no_hand" {
                        print("else");
                        apache.stopAnimating()
                    }
                }
            }
        }
    
    private func updateCoreML() {
        let pixbuff : CVPixelBuffer? = (arView.session.currentFrame?.capturedImage)
        if pixbuff == nil { return }
        
        let deviceOrientation = UIDevice.current.orientation.getImagePropertyOrientation()
        let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: pixbuff!, orientation: deviceOrientation,options: [:])
        do {
            try imageRequestHandler.perform(self.visionRequests)
        } catch {
            print(error)
        }
        
    }
    @objc private func loopCoreMLUpdate() {
       serialQueue.async {
           self.updateCoreML()
       }
   }
}
extension UIDeviceOrientation {
    func getImagePropertyOrientation() -> CGImagePropertyOrientation {
        switch self {
        case UIDeviceOrientation.portrait, .faceUp: return CGImagePropertyOrientation.right
        case UIDeviceOrientation.portraitUpsideDown, .faceDown: return CGImagePropertyOrientation.left
        case UIDeviceOrientation.landscapeLeft: return CGImagePropertyOrientation.up
        case UIDeviceOrientation.landscapeRight: return CGImagePropertyOrientation.down
        case UIDeviceOrientation.unknown: return CGImagePropertyOrientation.right
        }
    }
}
