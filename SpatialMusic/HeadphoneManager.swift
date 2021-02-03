//
//  HeadphoneManager.swift
//  SpatialMusic
//
//  Created by Yair Fax on 1/17/21.
//

import Foundation
import SwiftUI
import CoreMotion
import SceneKit

let flip = simd_float4x4(columns: (
    simd_float4(1, 0, 0, 0),
    simd_float4(0, 0, 1, 0),
    simd_float4(0, 1, 0, 0),
    simd_float4(0, 0, 0, 1)))

extension simd_float4x4 {
    init(_ m: CMRotationMatrix) {
        self.init(columns: (
            simd_float4(Float(m.m11), Float(m.m12), Float(m.m13), 0),
            simd_float4(Float(m.m21), Float(m.m22), Float(m.m23), 0),
            simd_float4(Float(m.m31), Float(m.m32), Float(m.m33), 0),
            simd_float4(           0,            0,            0, 1)))
    }
}

struct HeadphoneManager: UIViewControllerRepresentable {
    @Binding var state: String
    @Binding var recalibrate: Bool
    @Binding var clearCalibration: Bool
    @Binding var transformers: [Transformer]
    
    @State var bias = simd_float4x4(1)

    let motionManager = CMHeadphoneMotionManager()
    
    func makeUIViewController(context: Context) -> UIViewController {
        motionManager.delegate = context.coordinator
        
        if motionManager.isDeviceMotionAvailable {
            motionManager.startDeviceMotionUpdates(to: OperationQueue.main, withHandler: motionHandler)
        }
        let controller = UIViewController()
        return controller
    }
    
    func motionHandler(motion: CMDeviceMotion?, error: Error?) {
        let mat = motion?.attitude.rotationMatrix
        let transMatrix = doRotation(convertMatrix(mat))
        
        for transformer in transformers {
            transformer(transMatrix)
        }
    }
    
    func convertMatrix(_ src: CMRotationMatrix?) -> simd_float4x4 {
        return simd_float4x4(src!)
    }
    
    func doRotation(_ rotation: simd_float4x4) -> simd_float4x4 {
        let fullRotation = flip * rotation * flip
        
        if (recalibrate) {
            bias = fullRotation.inverse
            recalibrate = false
        } else if (clearCalibration) {
            bias = simd_float4x4(1)
            clearCalibration = false
        }

        return bias * fullRotation
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        
    }
    
    class Coordinator: NSObject, CMHeadphoneMotionManagerDelegate {
        var parent: HeadphoneManager
        
        init(_ parent: HeadphoneManager) {
            self.parent = parent
        }
        
        func headphoneMotionManagerDidConnect(_ manager: CMHeadphoneMotionManager) {
            parent.state = "Connected"
        }
        func headphoneMotionManagerDidDisconnect(_ manager: CMHeadphoneMotionManager) {
            parent.state = "Disconnected"
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
}
