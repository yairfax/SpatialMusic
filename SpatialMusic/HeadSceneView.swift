//
//  HeadSceneView.swift
//  SpatialMusic
//
//  Created by Yair Fax on 1/20/21.
//

import Foundation
import SwiftUI
import SceneKit

struct HeadSceneView: View {
    @Binding var recalibrate: Bool
    @Binding var clearCalibration: Bool
    @Binding var transformers: [Transformer]
    
    @State var scene = SCNScene(named: "Head.scn")
    var initHeadPos = simd_float4x4()

    init(recalibrate: Binding<Bool>, clearCalibration: Binding<Bool>, transformers: Binding<[Transformer]>) {
        self._recalibrate = recalibrate
        self._clearCalibration = clearCalibration
        self._transformers = transformers
        
        initHeadPos = (scene?.getTransform(node: "head"))!
    }
    
    func transformHead(_ transform: simd_float4x4) {
        let prevPos = (scene?.getTransform(node: "head"))!
        
        let animation = CABasicAnimation(keyPath: "transform")
        animation.fromValue = SCNMatrix4(prevPos)
        
        let newPos = transform * initHeadPos
        animation.toValue = SCNMatrix4(newPos)
        animation.duration = 0.2
        
        scene?.setTransform(node: "head", newPos)
        scene?.addAnimation(node: "head", animation)
    }
    
    var body: some View {
        SceneView(scene: scene)
            .contextMenu {
                Button(action: {
                    recalibrate = true
                }) {
                    Image(systemName: "dial.min.fill")
                    Text("Recalibrate")
                }
                Button(action: {
                    clearCalibration = true
                }) {
                    Image(systemName: "dial.min")
                    Text("Clear Calibration")
                }
            }
            .onAppear {
                transformers.append(transformHead)
            }
    }
}

extension SCNScene {
    func setTransform(node: String, _ transform: simd_float4x4) {
        (rootNode.childNode(withName: node, recursively: false))?.simdTransform = transform
    }
    
    func getTransform(node: String) -> simd_float4x4 {
        return (rootNode.childNode(withName: node, recursively: false))!.simdTransform
    }
    
    func addAnimation(node: String, _ animation: SCNAnimationProtocol) {
        (rootNode.childNode(withName: node, recursively: false))!.addAnimation(animation, forKey: nil)
    }
}
