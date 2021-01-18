//
//  ContentView.swift
//  SpatialMusic
//
//  Created by Yair Fax on 1/15/21.
//

import SwiftUI
import UIKit
import SceneKit

struct ContentView: View {
//    @State private var image: Image?
//    @State private var showingImagePicker = false
//    @State private var inputImage: UIImage?
    
    @State private var rotationText = "Rotation data here"
    @State private var state = "Disconnected"
    @State private var scene = SCNScene(named: "Head.scn")
    @State private var recalibrating = false
    @State private var bias = simd_float4x4(SCNMatrix4Identity)
//    func loadImage() {
//        guard let inputImage = inputImage else { return }
//        image = Image(uiImage: inputImage)
//    }
    
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
            SceneView(
                scene: scene
            )
//            Text(rotationText)
            Text(state)
                .padding()
            Button("Recalibrate", action: recalibrate)
            HeadphoneManager(
                text: self.$rotationText,
                state: self.$state,
                recalibrating: self.$recalibrating,
                headNode: self.scene?.rootNode.childNode(withName: "head", recursively: false),
                bias: self.$bias)
        }
    }
    
    func recalibrate() {
         recalibrating = true
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
