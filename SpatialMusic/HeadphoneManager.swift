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

let x = simd_float4(1, 0, 0, 0)
let y = simd_float4(0, 0, 1, 0)
let z = simd_float4(0, 1, 0, 0)
let w = simd_float4(0, 0, 0, 1)
let flip = simd_float4x4(columns: (x, y, z, w))

extension simd_float4x4 {
    init(_ m: CMRotationMatrix) {
        let x = simd_float4(Float(m.m11), Float(m.m21), Float(m.m31), 0)
        let y = simd_float4(Float(m.m12), Float(m.m22), Float(m.m32), 0)
        let z = simd_float4(Float(m.m13), Float(m.m23), Float(m.m33), 0)
        let w = simd_float4(           0,            0,            0, 1)
        self.init(columns: (x, y, z, w))
    }
}

struct HeadphoneManager: UIViewControllerRepresentable {
    @Binding var state: String
    @Binding var recalibrate: Bool
    @Binding var clearCalibration: Bool
    
    @State var bias = simd_float4x4(1)

    var transformations: [UpdateTransformation]
    
    let motionManager = CMHeadphoneMotionManager()
    
//    init(state: Binding<String>, recalibrating: Binding<Bool>, transformations: [UpdateTransformation]) {
//        self._state = state
//        self._recalibrate = recalibrate
//
//        self.transformations = transformations
//    }
    
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
        guard let trnmtn = doRotation(convertMatrix(mat)) else {
            state = "Error"
            return
        }
        
        for transform in transformations {
            transform(trnmtn)
        }
    }
    
    func convertMatrix(_ src: CMRotationMatrix?) -> simd_float4x4? {
        guard let m = src else {
            return nil
        }
        return simd_float4x4(m)
    }
    
    func doRotation(_ rotation: simd_float4x4?) -> simd_float4x4? {
        guard let rot = rotation else {
            return nil
        }
        
        let transRot = flip.inverse * rot * flip
        
        if (recalibrate) {
            bias = transRot.inverse
            recalibrate = false
        } else if (clearCalibration) {
            bias = simd_float4x4(1)
            clearCalibration = false
        }

        return transRot * bias
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
