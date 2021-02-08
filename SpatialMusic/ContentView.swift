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

typealias Transformer = (simd_float4x4) -> (Void)

struct ContentView: View {
    @State private var state = "Disconnected"
    @State private var recalibrate = false
    @State private var clearCalibration = false

    @State private var showingSongPicker = false
    @State private var pickedSong: MPMediaItem?
    
    @State private var transformers: [Transformer] = []

    var body: some View {
        VStack{
            HeadSceneView(
                recalibrate: self.$recalibrate,
                clearCalibration: self.$clearCalibration,
                transformers: self.$transformers
            )
//            RotationText(transformers: self.$transformers)
            Text(state)
                .padding()
            Button("Pick a Song") {
                self.showingSongPicker = true
            }
            MusicPlayer(
                pickedSong: pickedSong,
                transformers: self.$transformers)
            HeadphoneManager(
                state: self.$state,
                recalibrate: self.$recalibrate,
                clearCalibration: self.$clearCalibration,
                transformers: self.$transformers)
            
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

struct RotationText: View {
    @State var rotationText = "Rotation data here"
    
    @Binding var transformers: [Transformer]
    
    func printMatrix(_ transform: simd_float4x4) {
        let vals = [
            [transform.columns.0.x, transform.columns.2.x, transform.columns.3.x],
            [transform.columns.0.y, transform.columns.1.y, transform.columns.2.y],
            [transform.columns.0.z, transform.columns.1.z, transform.columns.2.z]]
        rotationText = vals.reduce("", {a, row in "\(a)\n[\(row.reduce("", {acc, val in "\(acc) \(String(format: "%.2f", val))"}))]" } )
    }
    
    var body: some View {
        Text(rotationText)
            .onAppear {
                transformers.append(printMatrix)
            }
    }
}
