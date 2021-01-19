//
//  MediaPicker.swift
//  SpatialMusic
//
//  Created by Yair Fax on 1/18/21.
//

import Foundation
import SwiftUI
import MediaPlayer

struct SongPicker: UIViewControllerRepresentable {
    @Environment(\.presentationMode) var presentationMode
    @Binding var pickedSong: MPMediaItem?
    
    func makeUIViewController(context: Context) -> MPMediaPickerController {
        let picker = MPMediaPickerController(mediaTypes: MPMediaType.music)
        picker.showsCloudItems = false
        picker.prompt = "Select a song"
        picker.showsItemsWithProtectedAssets = false
        picker.allowsPickingMultipleItems = false
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: MPMediaPickerController, context: Context) {
        
    }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }
    
    class Coordinator: NSObject, MPMediaPickerControllerDelegate {
        var parent: SongPicker
        
        init(_ parent: SongPicker) {
            self.parent = parent
        }
        
        func mediaPicker(_ mediaPicker: MPMediaPickerController, didPickMediaItems: MPMediaItemCollection) {
            parent.pickedSong = didPickMediaItems.items[0]
            print(parent.pickedSong!.value(forProperty: MPMediaItemPropertyAssetURL))
            parent.presentationMode.wrappedValue.dismiss()
        }
        
        
    }
}
