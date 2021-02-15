//
//  SceneObject.swift
//  apache
//
//  Created by Owner on 13/2/21.
//

import Foundation
import SceneKit

class SceneObject: SCNNode {
    
    init(from file: String) {
        super.init()
        
        let nodesInFile = SCNNode.allNodes(from: file)
        nodesInFile.forEach { (node) in
            self.addChildNode(node)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
