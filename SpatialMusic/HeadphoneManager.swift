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
    @Binding var text: String
    @Binding var state: String
    @Binding var recalibrating: Bool
    var headNode: SCNNode?
    
    @Binding var bias: simd_float4x4
    var initPos: simd_float4x4
    
    let motionManager = CMHeadphoneMotionManager()
    
    init(text: Binding<String>, state: Binding<String>, recalibrating: Binding<Bool>, headNode: SCNNode?, bias: Binding<simd_float4x4>) {
        self._text = text
        self._state = state
        self._recalibrating = recalibrating
        self.headNode = headNode
        self._bias = bias
        
        initPos = simd_float4x4(headNode!.transform)
    }
    
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
        text = matToString(mat: motion?.attitude.rotationMatrix)
        guard let transform = doRotation(convertMatrix(mat)) else {
            state = "Error"
            return
        }
        headNode?.transform = SCNMatrix4(transform)
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
        
        let transRot = flip * rot * flip.inverse
        
        if (recalibrating == true) {
            bias = transRot.inverse
            recalibrating = false
        }

        return transRot * bias * initPos
    }
    
    func matToString(mat: CMRotationMatrix?) -> String{
        guard let m = mat else {
            return "No rotation data available"
        }
        let vals = [[m.m11, m.m12, m.m13], [m.m21, m.m22, m.m23], [m.m31, m.m32, m.m33]]
        return vals.reduce("", {a, row in "\(a)\n[\(row.reduce("", {acc, val in "\(acc) \(String(format: "%.2f", val))"}))]" } )
    }
    
    func formatDouble(_ num: Double) -> String {
        return String(format: "%.2f", num)
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
