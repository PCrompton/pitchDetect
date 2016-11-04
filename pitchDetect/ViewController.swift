//
//  ViewController.swift
//  pitchDetect
//
//  Created by Work on 9/15/16.
//  Copyright © 2016 Paul Crompton. All rights reserved.
//

import UIKit
import Beethoven
import Pitchy
import AVFoundation

class ViewController: UIViewController, PitchEngineDelegate {
    
    @IBOutlet weak var startButton: UIButton!

    @IBOutlet weak var pitchLabel: UILabel!
    
    var pitchEngine: PitchEngine?
    var noteToPlay: Note?
    var lowest = try! Note(letter: .C, octave: 1)
    var highest = try! Note(letter: .C, octave: 7)
    var consecutivePitches = [Pitch]()
    let consecutiveMax = 3
    let bufferSize: AVAudioFrameCount = 4096
    let estimationStragegy = EstimationStrategy.yin
    let audioURL: URL? = nil
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let config = Config(bufferSize: bufferSize, estimationStrategy: estimationStragegy)
        pitchEngine = PitchEngine(config: config, delegate: self)
        pitchEngine?.levelThreshold = -30.0
    }

    @IBAction func StartButton(_ sender: UIButton) {
        if !pitchEngine!.active {
            pitchEngine?.start()
            print("Pitch Engine Started")
            noteToPlay = getNoteToPlayInRange(low: lowest, high: highest)
            pitchLabel.text = noteToPlay?.string
        } else {
            pitchEngine?.stop()
            print("Pitch Engine Stopped")
            pitchLabel.text = "Press Start"
        }
    }
    
    func getNoteToPlayInRange(low: Note, high: Note) -> Note {
        let range = high.index-low.index
        let index = Int(arc4random_uniform(UInt32(range+1))) + low.index
        return try! Note(index: index)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        pitchEngine?.stop()
    }
    
    func checkIfIsPitch(pitches: [Pitch]) -> Bool {
        for i in 1..<pitches.count {
            if pitches[i].note.index != pitches[i-1].note.index {
                return false
            }
        }
        return true
    }
    
    
    // Mark PitchEngineDelegate functions
    public func pitchEngineDidReceivePitch(_ pitchEngine: PitchEngine, pitch: Pitch) {
        let note = pitch.note
        print(note.string)
        if consecutivePitches.count < consecutiveMax {
            consecutivePitches.append(pitch)
        } else {
            consecutivePitches.remove(at: 0)
            consecutivePitches.append(pitch)
            let isPitch = checkIfIsPitch(pitches: consecutivePitches)
            if isPitch {
                pitchEngine.stop()
                consecutivePitches.removeAll()
                let alertController = UIAlertController(title: note.string, message: nil, preferredStyle: .alert)
                let action = UIAlertAction(title: "Next", style: .default) {
                    (action) in
                    self.pitchEngine?.start()
                    self.noteToPlay = self.getNoteToPlayInRange(low: self.lowest, high: self.highest)
                    self.pitchLabel.text = self.noteToPlay?.string
                }
                alertController.addAction(action)
                print(pitch.note.string, pitch.note.index)
                if note.index == noteToPlay!.index {
                    alertController.message = "Congrates, you played \(note.string)"
                } else {
                    alertController.message = "Sorry, that was not \(noteToPlay!.string)"
                    let action = UIAlertAction(title: "Try Again", style: .default) {
                        (action) in
                        self.pitchEngine?.start()
                    }
                    alertController.addAction(action)
                }
                
                present(alertController, animated: true)
            }
        }
    }
    
    public func pitchEngineDidReceiveError(_ pitchEngine: PitchEngine, error: Error) {
        print(Error.self)
    }
    
    public func pitchEngineWentBelowLevelThreshold(_ pitchEngine: PitchEngine) {
        //print("PitchEngine went below threshhold")
        return
    }

}

