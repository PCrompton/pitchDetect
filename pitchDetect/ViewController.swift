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
    var pitchEngine: PitchEngine?
    var noteToPlay: Note?
    var lowest = try! Note(letter: .C, octave: 3)
    var highest = try! Note(letter: .C, octave: 6)
    @IBOutlet weak var pitchLabel: UILabel!
    
    var consecutivePitches = [Pitch]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let config = Config(bufferSize: 4096, transformStrategy: .fft, estimationStrategy: .hps, audioURL: nil)
        pitchEngine = PitchEngine(config: config, delegate: self)
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
    
    func pitchEngineDidRecievePitch(_ pitchEngine: PitchEngine, pitch: Pitch) {
        let note = pitch.note
        print(note.string)
        if consecutivePitches.count < 5 {
            consecutivePitches.append(pitch)
        } else {
            consecutivePitches.remove(at: 0)
            consecutivePitches.append(pitch)
            let isPitch = checkIfIsPitch(pitches: consecutivePitches)
            if isPitch {
                pitchEngine.stop()
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
                    alertController.message = "Congrates, you played \(note.string)!"
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
    
    func pitchEngineDidRecieveError(_ pitchEngine: PitchEngine, error: Error) {
        print(Error.self)
    }

}

