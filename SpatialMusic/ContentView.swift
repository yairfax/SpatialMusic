//
//  ContentView.swift
//  SpatialMusic
//
//  Created by Yair Fax on 1/15/21.
//

import SwiftUI
import UIKit
import SceneKit
import MediaPlayer

typealias UpdateTransformation = (simd_float4x4) -> (Void)

struct ContentView: View {
//    @State private var image: Image?
//    @State private var showingImagePicker = false
//    @State private var inputImage: UIImage?
    
    @State private var rotationText = "Rotation data here"
    @State private var state = "Disconnected"
    @State private var recalibrate = false
    @State private var clearCalibration = false

    @State private var showingSongPicker = false
    @State private var pickedSong: MPMediaItem?
    
    private var scene = SCNScene(named: "Head.scn")
    private var headNode: SCNNode
    private var initHeadPos = simd_float4x4()
    @State private var prevPos = simd_float4x4()
    
//    func loadImage() {
//        guard let inputImage = inputImage else { return }
//        image = Image(uiImage: inputImage)
//    }
    
    init() {
        headNode = (self.scene?.rootNode.childNode(withName: "head", recursively: false))!
        initHeadPos = simd_float4x4(headNode.transform)
        prevPos = initHeadPos
    }
    
    func transformHead(_ transform: simd_float4x4) {
        let animation = CABasicAnimation(keyPath: "transform")
        animation.fromValue = SCNMatrix4(prevPos)
        prevPos = transform * initHeadPos
        animation.toValue = SCNMatrix4(transform * initHeadPos)
        animation.duration = 0.2
        headNode.addAnimation(animation, forKey: "transform")
    }
    
    func printMatrix(_ transform: simd_float4x4) {
        let vals = [
            [transform.columns.0.x, transform.columns.2.x, transform.columns.3.x],
            [transform.columns.0.y, transform.columns.1.y, transform.columns.2.y],
            [transform.columns.0.z, transform.columns.1.z, transform.columns.2.z]]
        rotationText = vals.reduce("", {a, row in "\(a)\n[\(row.reduce("", {acc, val in "\(acc) \(String(format: "%.2f", val))"}))]" } )
    }
    
    var body: some View {
//        VStack{
//            image?
//                .resizable()
//                .scaledToFit()
//
//            Button("Select Image") {
//                self.showingImagePicker = true
//            }
//        }
//        .sheet(isPresented: $showingImagePicker, onDismiss: loadImage) {
//            ImagePicker(image: self.$inputImage)
//        }
        VStack{
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
            Text(rotationText)
            Text(state)
                .padding()
            Button("Pick a Song") {
                self.showingSongPicker = true
            }
            HeadphoneManager(
                state: self.$state,
                recalibrate: self.$recalibrate,
                clearCalibration: self.$clearCalibration,
                transformations: [transformHead, printMatrix])
        }
        .sheet(isPresented: $showingSongPicker) {
            SongPicker(pickedSong: self.$pickedSong)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
