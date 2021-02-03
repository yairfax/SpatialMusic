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
    var pickedSong: MPMediaItem?
    private var audioFile: AVAudioFile?
    
    // MARK: State Vars
    
    @State private var seekPos = 0.0
    @State private var offsetFrame: AVAudioFramePosition = 0
    
    private var playingText = "Not Playing"
    @State private var timeString = "0:00"
    
    @State private var updaterActive = false
    @State private var paused = true
    private var started = false
    
    let player = AVAudioPlayerNode()
    let engine = AVAudioEngine()
    
    // MARK: Computed Vars
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
    init(pickedSong: MPMediaItem?) {
        self.pickedSong = pickedSong
        
        do {
            guard let url = pickedSong?.assetURL else {
                audioFile = nil
                return
            }

            let file = try AVAudioFile(forReading: url)
            audioFile = file

            engine.attach(player)
            engine.connect(player, to: engine.mainMixerNode, format: file.processingFormat)
            engine.prepare()
        
            try engine.start()
            
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
//        .onAppear(perform: onAppear)
    }
}
