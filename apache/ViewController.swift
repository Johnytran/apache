//
//  ViewController.swift
//  apache
//
//  Created by Owner on 10/2/21.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate, ARSessionDelegate {
    
    
    @IBOutlet weak var arView: ARSCNView!
    var sceneController = MainScene()
    
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
            translation.columns.3.z = -5.0
            let transform = camera.transform * translation
            let position = SCNVector3(transform.columns.3.x, transform.columns.3.y, transform.columns.3.z)
            sceneController.addApache(parent: arView.scene.rootNode, position: position)
        }
    }
    override func viewWillAppear(_ animated: Bool) {
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()

        // Run the view's session
        arView.session.run(configuration);
    }
}
