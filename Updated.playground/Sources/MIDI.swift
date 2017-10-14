// This is based on a MIDI framework that I made a few months ago and published at https://github.com/18praveenb/Swift-MIDI-Playground
import Foundation
import AVFoundation

public typealias Byte = UInt8

/// Ad-hoc namespace that should not be instantiated. Contains static functions for creating MIDI data.
/// Documentation assumes you are familiar with the MIDI spec. If you are not, you can find a reference at [this link](http://www.personal.kent.edu/~sbirch/Music_Production/MP-II/MIDI/an_introduction_to_midi_contents.htm).
/// Preferred usage: create an array of bytes by concatenating events such as MIDI.note( and MIDI.chord(, then use MIDI.file( passing this array as "contents" to create a valid array of bytes which can be fed to Data(bytes and then to an AVMIDIPlayer. MIDI.track and MIDI.headerChunk are discouraged use because they do not generate valid MIDI files on their own.
public struct MIDI {
    /// Using the MIDI table from [this link](https://www.midi.org/specifications/item/gm-level-1-sound-set)
    public static let Piano: Byte = 1
    public static let ElectricPiano: Byte = 5

    public static let Saxophone: Byte = 67
    public static let Trumpet: Byte = 57
    public static let SquareLead: Byte = 81

    public static let AcousticBass: Byte = 33
    public static let ElectricBass: Byte = 34
    public static let Cello: Byte = 43

    /// Using the table from [this link](https://www.midi.org/specifications/item/gm-level-1-sound-set)
    public static let Kick1: Byte = 35
    public static let Kick2: Byte = 36

    public static let Snare: Byte = 38
    public static let Clap: Byte = 39

    public static let HiHat1: Byte = 42
    public static let HiHat2: Byte = 46

    public static let Crash1: Byte = 49
    public static let Crash2: Byte = 57

    public static let Tambourine: Byte = 54
    public static let Cowbell: Byte = 56

    /// Use only at start of running status. Change channel from 0 via bitwise AND with a channel.
    /// Use noteOn (or running status) with zero velocity for noteOff
    public static let noteOn: Byte = 0x90
    public static let programChange: Byte = 0xC0
    public static let drumChannel: Byte = 9

    /// Based on MIDI table from [this link](https://usermanuals.finalemusic.com/Finale2012Mac/Content/Finale/MIDI_Note_to_Pitch_Table.htm).
    /// a[0] = a0, a[3] = a3 etc.
    /// Goes up to [8] only because a[9] and some others are out of range (pitch maximum is 127).
    /// To access negative pitches, subtract a P8. c[-1] is the lowest possible pitch.
    public static let c: [Byte] = (0...8).map {12*(Byte($0)+1)}
    public static let csharp: [Byte] = c.map {$0+m2}
    public static let dflat = csharp
    public static let d: [Byte] = csharp.map {$0+m2}
    public static let dsharp: [Byte] = d.map {$0+m2}
    public static let eflat: [Byte] = dsharp
    public static let e: [Byte] = dsharp.map {$0+m2}
    public static let f: [Byte] = e.map {$0+m2}
    public static let fsharp: [Byte] = f.map {$0+m2}
    public static let gflat: [Byte] = fsharp
    public static let g: [Byte] = fsharp.map {$0+m2}
    public static let gsharp: [Byte] = g.map {$0+m2}
    public static let aflat: [Byte] = gsharp
    public static let a: [Byte] = gsharp.map {$0+m2}
    public static let asharp: [Byte] = a.map {$0+m2}
    public static let bflat: [Byte] = asharp
    public static let b: [Byte] = asharp.map{$0+m2}

    /// Offsets from the root
    public static let P1: Byte = 0
    public static let m2: Byte = 1
    public static let M2: Byte = 2
    public static let m3: Byte = 3
    public static let M3: Byte = 4
    public static let P4: Byte = 5
    public static let TT: Byte = 6
    public static let P5: Byte = 7
    public static let m6: Byte = 8
    public static let M6: Byte = 9
    public static let m7: Byte = 10
    public static let M7: Byte = 11
    public static let P8: Byte = 12

    public static let headerType: [Byte] = [0x4D, 0x54, 0x68, 0x64]
    public static let chunkType: [Byte] = [0x4D, 0x54, 0x72, 0x6B]
    public static let headerLength: [Byte] = [0x00, 0x00, 0x00, 0x06]
    public static let endOfTrack: [Byte] = [0x00, 0xFF, 0x2F, 0x00]

    /// The default value of a quarter note
    public static let defaultDivision: UInt16 = 0x60

    public enum HeaderChunkMode {
        case SingleTrack
        case SimultaneousTracks(num: UInt16)
        case IndependentTracks(num: UInt16)
        public var bytes: [Byte] {
            switch self {
            case .SingleTrack: return [0x00, 0x00]
            case .SimultaneousTracks(_): return [0x00, 0x01]
            case .IndependentTracks(_): return [0x00, 0x02]
            }
        }
    }

    /// - parameter division: defaults to 0x18 because that can get triplets evenly.
    public static func headerChunk(mode: HeaderChunkMode, division: UInt16 = defaultDivision) -> [Byte] {
        let numTracks: UInt16
        switch mode {
        case .SingleTrack: numTracks = 1
        case .SimultaneousTracks(let num), .IndependentTracks(let num): numTracks = num
        }
        return headerType + headerLength + mode.bytes + toBytes(numTracks) + toBytes(division)
    }

    /// Adds track header and end of track around contents.
    public static func track(contents: [Byte]) -> [Byte] {
        return chunkType + toBytes(UInt32(contents.count)) + contents + endOfTrack
    }

    /// Return a complete, usable MIDI file from the specified contents
    public static func file(mode: HeaderChunkMode, contents: [Byte], division: UInt16 = defaultDivision) -> [Byte] {
        return headerChunk(mode: mode, division: division) + track(contents: contents)
    }

    /// Construct a MIDI note with the specified characteristics. Does not optimize with running status, but is guaranteed to return a valid note. To stack multiple notes, use the chord function because concatenated notes from this function will play in sequence, not simultaneously.
    /// - parameter
    /// - parameter offset: from 0x00, which would play the note immediately after the previous event
    /// - parameter velocity: from 0 to 127
    /// - parameter channel: defaults to 0. Note that I use zero instead of one indexing for channels.
    public static func note(pitch: Byte, velocity: Byte, duration: UInt32, offset: UInt32 = 0, channel: Byte = 0) -> [Byte] {
        let noteOnMessage = noteOn | channel
        return toVariableLength(offset) + [noteOnMessage, pitch, velocity] + toVariableLength(duration) + [noteOnMessage, pitch, 0]
    }

    public static func note(aNote: Note) -> [Byte] {
        return note(pitch: aNote.pitch, velocity: aNote.velocity, duration: aNote.duration, offset: aNote.offset, channel: aNote.channel)
    }

    /// A note, or the root of a chord
    /// To create a drum note, use channel: MIDI.drumChannel and then pitch: MIDI.Drum.<thing>.rawValue
    public struct Note {
        public var pitch: Byte
        public var velocity: Byte
        public var duration: UInt32
        public var offset: UInt32
        public var channel: Byte
        public init(pitch: Byte, velocity: Byte, duration: UInt32, offset: UInt32 = 0, channel: Byte = 0) {
            self.pitch = pitch
            self.velocity = velocity
            self.duration = duration
            self.offset = offset
            self.channel = channel
        }
    }

    /// A note in a chord whose properties are derived from the root Note
    public struct ChordMember {
        public enum Pitch {case Absolute(Byte), Interval(Byte)}
        /// from the root
        public var pitch: Pitch
        /// if nil, follow root
        public var velocity: Byte?
        /// if nil, follow root
        public var duration: UInt32?
        /// from the root
        public var offset: UInt32
        /// maximum of 0x0F; if nil, follow root
        public var channel: Byte?
        public init(pitch: Pitch, velocity: Byte? = nil, duration: UInt32? = nil, offset: UInt32 = 0, channel: Byte? = nil) {
            self.pitch = pitch
            self.velocity = velocity
            self.duration = duration
            self.offset = offset
            self.channel = channel
        }
    }

    /// Construct a MIDI chord with the specified members, whose properties derive from the root note.
    /// - parameter root: *NOT* included in the chord by default. It must be specifically added using the interval of P1.
    /// - parameter intervals: All from the root.
    /// - parameter channels: Zero indexed.
    public static func chord(root: Note, members: [ChordMember]) -> [Byte] {
        // The basic idea behind this algorithm is that we figure out when each noteOn and noteOff event occurs and place them in order from earliest to latest, computing delta times between them.
        var bytes = [Byte]()
        struct ChordEvent {
            var pitch: Byte
            var velocity: Byte
            var time: UInt32
            var channel: Byte
        }
        var events = [ChordEvent]()
        for member in members {
            let pitch: Byte; switch member.pitch {
            case .Absolute(let absolute): pitch = absolute
            case .Interval(let interval): pitch = root.pitch + interval
            }
            let velocity = member.velocity ?? root.velocity
            let channel = member.channel ?? root.channel
            let startTime = member.offset
            let endTime = startTime + (member.duration ?? root.duration)
            let noteOnEvent = ChordEvent(pitch: pitch, velocity: velocity, time: startTime, channel: channel)
            let noteOffEvent = ChordEvent(pitch: pitch, velocity: 0, time: endTime, channel: channel)
            events += [noteOnEvent, noteOffEvent]
        }
        events.sort{$0.time<$1.time}
        var lastEventTime: UInt32 = 0
        for i in 0..<events.count {
            bytes += toVariableLength(events[i].time - lastEventTime) + [noteOn | events[i].channel, events[i].pitch, events[i].velocity]
            lastEventTime = events[i].time
        }
        return bytes
    }

    /// A program change event changes the instrument used by the current track.
    public static func programChange(to: Byte, offset: UInt32 = 0, channel: Byte = 0) -> [Byte] {
        return toVariableLength(offset) + [programChange | channel, to]
    }

    /// Get delta time bytes for a given note duration. It's not in variable-length, but most functions will automatically convert it, and the toVariableLength function can also do this.
    /// - parameter number: 1 = whole note, 4 = quarter, 8 = eighth etc. **0 returns 0x00 i.e. no delay** If you need a value greater than a whole note, use multiplication on the return value of this function.
    /// - parameter dotted: defaults to false
    /// - parameter quarterNote: i.e. "division" from header chunk
    public static func duration(_ number: Int, dotted: Bool = false, quarterNote: UInt16 = defaultDivision) -> UInt32 {
        return number == 0 ? 0 : UInt32(quarterNote) * 4 * (dotted ? 3 : 2) / 2 / UInt32(number)
    }

    /// Convert from UInt32 to variable length bytes used as delta times by MIDI.
    /// Props to [Wikipedia](https://en.wikipedia.org/wiki/Variable-length_quantity) for the basic algorithm
    public static func toVariableLength(_ value: UInt32) -> [Byte] {
        var bytes = [Byte]()
        bytes.append(Byte(value & 0x7F))
        for i: UInt32 in 1...4 {
            bytes.append(Byte(((value >> (7*i)) & 0x7F) | 0x80))
        }
        bytes.reverse()
        var numberToRemove = 0
        for i in 0..<bytes.count {
            if bytes[i] == 0x80 {numberToRemove += 1}
            else {break}
        }
        bytes.removeFirst(numberToRemove)
        return bytes
    }

    /// Convert from variable length bytes (i.e. delta times) back to UInt32, on which you can do arithmetic operations.
    public static func fromVariableLength(_ deltaTime: [Byte]) -> UInt32 {
        var value: UInt32 = 0
        let numValues = deltaTime.count
        for i in 0..<numValues {
            var bits = UInt32(deltaTime[i] & 0b0111_1111) // throw away the 7th bit
            bits = bits << UInt32(7 * (numValues - i - 1)) // move it into the proper place; most significant bits are first in the array and get shifted over the most. Note that for the last one, i = numValues - 1, we want to shift by 0 because it is least significant.
            value += bits
        }
        return value
    }

    /// Helper function that can represent an 32 bit integer as a 4 byte array
    public static func toBytes(_ int: UInt32) -> [Byte] {
        var bytes: [Byte] = []
        for i in 0..<4 {
            let toByte = int >> UInt32(8*i)
            let byte = Byte(truncatingIfNeeded: toByte)
            bytes.append(byte)
        }
        return bytes.reversed()
    }

    /// Helper function that calls toBytes for a 32 bit integer and throws away the 2 zero bytes to get a 2 byte array
    public static func toBytes(_ int: UInt16) -> [Byte] {
        return Array(toBytes(UInt32(int))[2...3]) // throw away the two high order bytes (zeroes)
    }

    public static func tempo(bpm: Int) -> [Byte] {
        return [0x00, 0xFF, 0x51, 0x03] + toBytes(60_000_000 / UInt32(bpm))[1...3]
    }
}
