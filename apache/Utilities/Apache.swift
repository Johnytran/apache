//
//  Apache.swift
//  apache
//
//  Created by Owner on 14/2/21.
//

import Foundation
import SceneKit

class Apache: SceneObject {
    
    var animating: Bool = false
    
    init() {
        super.init(from: "apache.dae")
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    

   func animate() {
       
       if animating { return }
       animating = true
       
       let rotateOne = SCNAction.rotateBy(x: 0, y: CGFloat(Float.pi * 2), z: 0, duration: 5.0)
       let repeatForever = SCNAction.repeatForever(rotateOne)

       runAction(repeatForever)
   }
   
   func stopAnimating() {
       removeAllActions()
       animating = false
   }
}
