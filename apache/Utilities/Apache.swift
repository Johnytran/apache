//
//  Apache.swift
//  apache
//
//  Created by Owner on 14/2/21.
//

import Foundation
import SceneKit

class Apache: SceneObject {
    
    init() {
        super.init(from: "apache.dae")
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
