//
//  Camera.swift
//  ColoredPointCloud
//
//  Created by hvrl_mt on 2022/05/08.
//

import Foundation
import ARKit

class Camera {
    var lastTransform = simd_float4x4()
    
    // Camera's threshold values for detecting when the camera moves so that we can accumulate the points
    let rotationThreshold = cos(2 * .degreesToRadian)
    let translationThreshold: Float = pow(0.02, 2)   // (meter-squared)
    
    init() {
        update()
    }
    
    func update() {
        guard let sampleFrame = Renderer.session.currentFrame else {
            return
        }
        
        let camera = sampleFrame.camera
        lastTransform = camera.transform
    }
}
