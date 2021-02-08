//
//  MusicPlayer.swift
//  SpatialMusic
//
//  Created by Yair Fax on 1/21/21.
//

import Foundation
import SwiftUI
import MediaPlayer
import DisplayLink

struct MusicPlayer: View {
    @Binding var transformers: [Transformer]
    
    var pickedSong: MPMediaItem?
    private var audioFile: AVAudioFile?
    
    // MARK: State Vars
    @State private var seekPos = 0.0
    @State private var offsetFrame: AVAudioFramePosition = 0
    @State private var timeString = "0:00"
    
    @State private var updaterActive = false
    @State private var paused = true
    
    static let player = AVAudioPlayerNode()
    static let engine = AVAudioEngine()
    static let speakerNode = AVAudioEnvironmentNode()

    // MARK: Struct Vars
    private var playingText = "Not Playing"
    private var started = false
        
    let forward = simd_float4(0, 0, -1, 0)
    let up = simd_float4(0, 1, 0, 0)
    
    // MARK: Computed Vars
    private var player: AVAudioPlayerNode {return MusicPlayer.player}
    private var engine: AVAudioEngine {return MusicPlayer.engine}
    private var speakerNode: AVAudioEnvironmentNode {return MusicPlayer.speakerNode}
    
    private var songSampleLength: AVAudioFramePosition {
        guard let file = audioFile else {
            return 0
        }
        return file.length
    }
    
    private var songLength: TimeInterval {
        guard let song = pickedSong else {
            return 0
        }
        return song.playbackDuration
    }
    
    private var sampleRate: Double {
        guard let file = audioFile else {
            return 0
        }
        return file.fileFormat.sampleRate
    }
    
    private var currentFrame: AVAudioFramePosition {
        guard let lastRenderTime = player.lastRenderTime, let playerTime = player.playerTime(forNodeTime: lastRenderTime) else {
            return offsetFrame
        }
        return offsetFrame + playerTime.sampleTime
    }
    
    private var currentTime: Double {
        if sampleRate == 0.0 {
            return 0.0
        }
        return Double(currentFrame) / sampleRate
    }
        
    // MARK: Init
    init(pickedSong: MPMediaItem?, transformers: Binding<[Transformer]>) {
        self.pickedSong = pickedSong
        self._transformers = transformers
        
        do {
            guard let url = pickedSong?.assetURL else {
                audioFile = nil
                return
            }

            let file = try AVAudioFile(forReading: url)
            audioFile = file
            
            if (!engine.isRunning) {
                engine.attach(speakerNode)
                
                speakerNode.sourceMode = AVAudio3DMixingSourceMode.pointSource
                speakerNode.listenerPosition = AVAudio3DPoint(x: 0, y: 0, z: 0)
                speakerNode.listenerVectorOrientation = AVAudio3DVectorOrientation(forward: AVAudio3DVector(x: 0, y: 0, z: -1), up: AVAudio3DVector(x: 0, y: 1, z: 0))
                speakerNode.renderingAlgorithm = AVAudio3DMixingRenderingAlgorithm.sphericalHead
                
                speakerNode.distanceAttenuationParameters.referenceDistance = 0.5
                
                speakerNode.reverbParameters.enable = true
                speakerNode.reverbParameters.level = -20.0
                speakerNode.reverbParameters.loadFactoryReverbPreset(AVAudioUnitReverbPreset.smallRoom)
                
                engine.connect(speakerNode, to: engine.mainMixerNode, format: nil)
                
                try engine.start()
                
                engine.attach(player)
                player.position = AVAudio3DPoint(x: 0.2, y: 0, z: 1)
                player.reverbBlend = 0.5
                
                engine.connect(player, to: speakerNode, format:
                                AVAudioFormat.init(standardFormatWithSampleRate: file.fileFormat.sampleRate, channels: 1))
            } else {
                player.stop()
            }

            player.scheduleFile(file, at: nil)
            
            started = true
            
            playingText = "Playing \(self.pickedSong?.title ?? "")"
        } catch {
            print("Unexpected error: \(error).")
            return
        }
    }
    
    // MARK: Update Functions
    func updateTicker(_ frame: DisplayLink.Frame) {
        seekPos = Double(currentFrame) / Double(songSampleLength)
        timeString = formatTime(Int(floor(seekPos * songLength)))
        
        if (seekPos > 0.99) {
            songEnd()
        }
    }
    
    func formatTime(_ numSecs: Int) -> String {
        return String(format: "%d:%02d", numSecs / 60, numSecs % 60)
    }
    
    func buttonAction() {
        if started {
            if !paused {
                player.pause()
                paused = true
                updaterActive = false
            } else {
                player.play()
                paused = false
                updaterActive = true
            }
        }
    }
    
    func sliderUpdate(_ pressed: Bool) {
        if (!pressed) {
            guard let file = audioFile else {
                return
            }
            
            let targetTime = seekPos * songLength
            let targetSampleTime = AVAudioFramePosition(floor(targetTime * sampleRate))
            
            offsetFrame = targetSampleTime
            
            let samplesLeft = songSampleLength - targetSampleTime
            
            player.stop()
            player.scheduleSegment(file, startingFrame: AVAudioFramePosition(targetSampleTime), frameCount: AVAudioFrameCount(samplesLeft), at: nil, completionHandler: {player.pause()})
            if (!paused) {
                player.play()
            }
        }
        updaterActive = !pressed
    }
        
    func resetValues(_ song: MPMediaItem?) {
        timeString = "0:00"
        offsetFrame = 0
        seekPos = 0
        updaterActive = false
        paused = true
    }
    
    func songEnd() {
        resetValues(nil)
        if let file = audioFile {
            player.scheduleFile(file, at: nil)
        }
    }
    
    func transformHead(_ transform: simd_float4x4) {
        speakerNode.listenerVectorOrientation = AVAudio3DVectorOrientation(forward: AVAudio3DVector(transform * forward), up: AVAudio3DVector(transform * up))
    }
    
    // MARK: Body Definition
    var body: some View {
        VStack{
            HStack {
                Button(action: buttonAction) {
                    Image(systemName: paused ? "play" : "pause")
                        .padding()
                }
                Slider(
                    value: $seekPos,
                    in: 0...1,
                    onEditingChanged: sliderUpdate
                )
                Text(timeString)
            }
            Text(playingText)
        }
        .onFrame(isActive: updaterActive, updateTicker)
        .onChange(of: pickedSong, perform: resetValues)
        .onAppear {
            transformers.append(transformHead)
        }
    }
}

extension AVAudio3DVector {
    init(_ v: simd_float4) {
        self.init(x: v.x, y: v.y, z: v.z)
    }
}
