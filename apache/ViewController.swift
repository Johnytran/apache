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
    var centeredNode: SCNNode?
    
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

        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(ViewController.didTapScreen))
        tapRecognizer.numberOfTapsRequired = 1
        tapRecognizer.numberOfTouchesRequired = 1
        self.view.addGestureRecognizer(tapRecognizer)
    }
    
    @objc func didTapScreen(recognizer: UITapGestureRecognizer) {
        if let camera = arView.session.currentFrame?.camera {
            var translation = matrix_identity_float4x4
            translation.columns.3.z = -7.0
            let transform = camera.transform * translation
            let position = SCNVector3(transform.columns.3.x, transform.columns.3.y, transform.columns.3.z)
            sceneController.addApache(parent: arView.scene.rootNode, position: position)
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        // Check all the nodes if they are inside our frustrum
        for node in arView.scene.rootNode.childNodes {
            guard let pointOfView = renderer.pointOfView else { return }
            let isVisible = renderer.isNode(node, insideFrustumOf: pointOfView)
            
            if isVisible, let apache = node as? Apache {
                // get the extents of the screen
                let screenWidth = UIScreen.main.bounds.width
                let screenHeight = UIScreen.main.bounds.height
                
                // Define a length for determining if an object is within a certain distance from the center of the screen
                let buffer: CGFloat = 120.0
                
                // Define the rectangle that serves as the "center" area
                let topLeftPoint = CGPoint(x: screenWidth/2 - buffer, y: screenHeight/2 - buffer)
                let screenRect = CGRect(origin: topLeftPoint, size: CGSize(width: buffer * 2, height: buffer * 2))
                
                // Get the world position of the object in screen space, strip out the Z, and create a CGPoint
                let screenPos = renderer.projectPoint(apache.worldPosition)
                let xyPos = CGPoint(x: CGFloat(screenPos.x), y: CGFloat(screenPos.y))
                
                // If this object is centered, then set it to the centeredNode var
                let isCentered = screenRect.contains(xyPos)
                if isCentered {
                    centeredNode = apache
                }
            }
        }
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
