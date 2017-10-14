//: # Computer generated music
//: ## (updated version of) WWDC playground by Praveen Batra
//: Music generator with a lot of different options.
import Cocoa
import PlaygroundSupport
import AVFoundation
//: ### Live view setup
let view = NSImageView(image: #imageLiteral(resourceName: "background_image.001.jpeg"))
view.frame = CGRect(x: 0, y: 0, width: 400, height: 400)
PlaygroundPage.current.liveView = view
//: ### UI-related classes and functions
func newButton(name: String, origin: CGPoint, target: Any? = nil, action: Selector? = nil) -> NSButton {
    let button = NSButton(title: name, target: target, action: action)
    button.frame.origin = origin
    view.addSubview(button)
    return button
}

class SegmentedControl: NSSegmentedControl {
    var labels = [String]()
}

func newSegmentedControl(labels: [String], origin: CGPoint) -> SegmentedControl {
    let control = SegmentedControl(labels: labels, trackingMode: .selectOne, target: nil, action: nil)
    control.frame.origin = origin
    control.labels = labels
    control.selectSegment(withTag: 0)
    view.addSubview(control)
    return control
}

class Slider: NSView {
    var slider: NSSlider?
    var text: NSTextField?
    var message: String
    init(value: Double, minValue: Double, maxValue: Double, origin: CGPoint, message: String) {
        self.message = message
        super.init(frame: NSRect(origin: CGPoint(), size: CGSize(width: 400, height: 400)))
        slider = NSSlider(value: value, minValue: minValue, maxValue: maxValue, target: self, action: #selector(Slider.updateValue))
        text = NSTextField(string: "\(slider?.intValue ?? -1)" + message)
        text?.isEditable = false
        text?.isSelectable = false
        slider?.frame.origin = origin
        text?.frame.origin = CGPoint(x: origin.x + 100, y: origin.y)
        if let uSlider = slider {addSubview(uSlider)}
        if let uText = text {addSubview(uText)}
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc func updateValue() {
        text?.stringValue = "\(slider?.intValue ?? -1)" + message
    }
}
//: ### Creating UI controls programmatically
let bars = Slider(value: 12, minValue: 4, maxValue: 16, origin: CGPoint(x: 0, y: 300), message: " measures")
view.addSubview(bars)
let ornament = Slider(value: 20, minValue: 0, maxValue: 50, origin: CGPoint(x: 0, y: 275), message: "% solo ornamentation rate")
view.addSubview(ornament)
let silent = Slider(value: 20, minValue: 0, maxValue: 50, origin: CGPoint(x: 0, y: 250), message: "% solo skip note rate")
view.addSubview(silent)
let tempo = Slider(value: 150, minValue: 30, maxValue: 300, origin: CGPoint(x: 0, y: 225), message: " beats per minute")
view.addSubview(tempo)
let key = newSegmentedControl(labels: ["C", "C♯", "D", "E", "F", "F♯", "G", "G♯", "A", "A♯", "B"], origin: CGPoint(x: 0, y: 200))
let mode = newSegmentedControl(labels: ["Major", "Minor", "Dorian", "Phrygian", "Lydian", "Locrian"], origin: CGPoint(x: 0, y: 175))
let timeSignature = newSegmentedControl(labels: ["4/4", "6/8", "3/4", "5/4", "7/8"], origin: CGPoint(x: 0, y: 150))
let chordLabels: [String:String] = [
    "🎸Rock" : "Rock",
    "🏔Ascending" : "Ascending",
    "Circle Progression" : "Circle"
]
let chords = newSegmentedControl(labels: Array(chordLabels.keys), origin: CGPoint(x: 0, y: 125))
let pianoLabels: [String:Byte] = [
    "🎹Acoustic Piano" : MIDI.Piano,
    "🎹Electric Piano" : MIDI.ElectricPiano
]
let piano = newSegmentedControl(labels: Array(pianoLabels.keys), origin: CGPoint(x: 0, y: 100))
let brassLabels : [String:Byte] = [
    "🎷Saxophone" : MIDI.Saxophone,
    "🎺Trumpet" : MIDI.Trumpet,
    "🎹Square Lead" : MIDI.SquareLead
]
let brass = newSegmentedControl(labels: Array(brassLabels.keys), origin: CGPoint(x: 0, y: 75))
let guitarLabels : [String:Byte] = [
    "🎸Acoustic Bass" : MIDI.AcousticBass,
    "🎸Electric Bass" : MIDI.ElectricBass,
    "🎻Cello" : MIDI.Cello
]
let guitar = newSegmentedControl(labels: Array(guitarLabels.keys), origin: CGPoint(x: 0, y: 50))
let drumsLabels: [String:Int] = [
    "🥁Drummer 1" : 1,
    "🥁Drummer 2" : -1
]
let drums = newSegmentedControl(labels: Array(drumsLabels.keys), origin: CGPoint(x: 0, y: 25))
//: ### Musical logic
enum ChordQuality {
    case maj, min, aug, dim, maj7, min7, dom7, dim7, hdim7
    var intervals: [Byte] {
        switch self {
        case .maj: return [MIDI.P1, MIDI.M3, MIDI.P5]
        case .min: return [MIDI.P1, MIDI.m3, MIDI.P5]
        case .aug: return [MIDI.P1, MIDI.M3, MIDI.m6]
        case .dim: return [MIDI.P1, MIDI.m3, MIDI.TT]
        case .maj7: return [MIDI.P1, MIDI.M3, MIDI.P5, MIDI.M7]
        case .min7: return [MIDI.P1, MIDI.m3, MIDI.P5, MIDI.m7]
        case .dom7: return [MIDI.P1, MIDI.M3, MIDI.P5, MIDI.m7]
        case .dim7: return [MIDI.P1, MIDI.m3, MIDI.TT, MIDI.M6]
        case .hdim7: return [MIDI.P1, MIDI.m3, MIDI.TT, MIDI.m7]
        }
    }
}

struct Scale {
    static let intervals: [Byte] = [MIDI.P1, MIDI.M2, MIDI.M3, MIDI.P4, MIDI.P5, MIDI.M6, MIDI.M7, MIDI.P8]
    static let qualities: [ChordQuality] = [.maj, .min, .min, .maj, .maj, .min, .dim, .maj]
    static let modes = ["Major", "Dorian", "Phrygian", "Lydian", "Mixolydian", "Minor", "Locrian", "Major"]
    static func processed(degree: Int, mode: String) -> Int {
        return clamped(degree + (modes.index(of: mode) ?? 0)) - 1
    }
    static func getInterval(mode: String, degree: Int) -> Byte {
        return intervals[processed(degree: degree, mode: mode)]
    }
    static func getQuality(mode: String, degree: Int) -> ChordQuality {
        return qualities[processed(degree: degree, mode: mode)]
    }
    static func clamped(_ idegree: Int) -> Int {
        var degree = idegree
        while (degree < 1) {degree += 7}
        while (degree > 8) {degree -= 7}
        return degree
    }
}

class ChordGenerator {
    var tonic: Byte
    var mode: String
    var type: String
    var scaleDegree: Int
    var quality: ChordQuality

    init(tonic: Byte, type: String, mode: String) {
        self.tonic = tonic
        self.mode = mode
        self.type = type
        self.scaleDegree = 1
        self.quality = Scale.getQuality(mode: mode, degree: self.scaleDegree)
    }

    func natural() -> ChordQuality { // natural chord quality of the current scale degree
        return Scale.getQuality(mode: mode, degree: scaleDegree)
    }

    func nextChord() -> (Byte, ChordQuality) {
        let currRoot = Scale.getInterval(mode: mode, degree: scaleDegree)
        let currQuality = self.quality

        if type == "Ascending" {
            scaleDegree += 1
            quality = natural()
        }

        else if type == "Circle" {
            scaleDegree -= 4
            quality = percentChance(50) ? .dom7 : natural()
        }
        else if quality == .dom7 {
            scaleDegree -= 4
            quality = natural()
        }

        else if [.dim, .dim7, .hdim7].index(of: quality) != nil {
            scaleDegree += 1
            quality = natural()
        }

        else {switch Scale.clamped(scaleDegree) { // Rock
        case 1, 8:
            let random = randomInt(below: 100)
            if random < 33 {scaleDegree = 2; quality = natural()}
            else if random < 67 {scaleDegree = 4; quality = natural()}
            else {scaleDegree = 6; quality = natural()}
        case 2:
            let random = randomInt(below: 100)
            if random < 20 {scaleDegree = 4; quality = natural()}
            else if random < 100 {scaleDegree = 5; quality = natural()}
        case 3:
            let random = randomInt(below: 100)
            if random < 50 {scaleDegree = 4; quality = natural()}
            else if random < 100 {scaleDegree = 6; quality = natural()}
        case 4:
            let random = randomInt(below: 100)
            if random < 20 {scaleDegree = 6; quality = natural()}
            else if random < 20 {scaleDegree = 2; quality = natural()}
            else if random < 30 {scaleDegree = 1; quality = natural()}
            else if random < 100 {scaleDegree = 5; quality = natural()}
        case 5:
            let random = randomInt(below: 100)
            if random < 20 {scaleDegree = 6; quality = natural()}
            else if random < 100 {scaleDegree = 1; quality = natural()}
        case 6:
            let random = randomInt(below: 100)
            if random < 15 {scaleDegree = 7; quality = natural()}
            else if random < 70 {scaleDegree = 2; quality = natural()}
            else if random < 100 {scaleDegree = 4; quality = natural()}
        case 7:
            let random = randomInt(below: 100)
            if random < 70 {scaleDegree = 1; quality = natural()}
            else if random < 80 {scaleDegree = 3; quality = natural()}
            else if random < 100 {scaleDegree = 4; quality = natural()}
        default: scaleDegree = 1; quality = natural()
            }
        }
        scaleDegree = Scale.clamped(scaleDegree)
        return (currRoot, currQuality)
    }
}
//: ### Player and instruments
class Player: NSObject {
    var player: AVMIDIPlayer?

    func generate() -> [Byte] {
        var bytes: [Byte] = []

        let tonic: Byte
        switch key.labels[key.selectedSegment] {
        case "C": tonic = MIDI.c[3]
        case "C♯": tonic = MIDI.csharp[3]
        case "D": tonic = MIDI.d[3]
        case "D♯": tonic = MIDI.dsharp[3]
        case "E": tonic = MIDI.e[3]
        case "F": tonic = MIDI.f[3]
        case "F♯": tonic = MIDI.fsharp[3]
        case "G": tonic = MIDI.g[3]
        case "G♯": tonic = MIDI.gsharp[3]
        case "A": tonic = MIDI.a[3]
        case "A♯": tonic = MIDI.asharp[3]
        case "B": tonic = MIDI.b[3]
        default: tonic = MIDI.c[3]
        }

        let type: String = chordLabels[chords.labels[chords.selectedSegment]] ?? "Rock"

        let modeStr = mode.labels[mode.selectedSegment]
        let generator = ChordGenerator(tonic: tonic, type: type, mode: modeStr)

        let timeString = timeSignature.labels[timeSignature.selectedSegment].components(separatedBy: "/")
        let time: (Int, Int) = (Int(timeString[0]) ?? 4, Int(timeString[1]) ?? 4)

        bytes += MIDI.tempo(bpm: Int(tempo.slider?.intValue ?? 120))

        var musicians = [Musician]()

        musicians.append(ChordalAccompaniment(channel: 1, time: time, tonic: tonic, mode: modeStr))
        bytes += MIDI.programChange(to: pianoLabels[piano.labels[piano.selectedSegment]] ?? MIDI.Piano, channel: 1)

        musicians.append(Bass(channel: 2, time: time, tonic: tonic, mode: modeStr))
            bytes += MIDI.programChange(to: guitarLabels[guitar.labels[guitar.selectedSegment]] ?? MIDI.AcousticBass, channel: 2)

        musicians.append(Melody(channel: 3, time: time, tonic: tonic, mode: modeStr))
        bytes += MIDI.programChange(to: brassLabels[brass.labels[brass.selectedSegment]] ?? MIDI.Saxophone, channel: 3)

        let drummer = Drummer(channel: MIDI.drumChannel, time: time, tonic: tonic, mode: modeStr)
        drummer.type = drumsLabels[drums.labels[drums.selectedSegment]] ?? 1
        musicians.append(drummer)

        let max = Int(bars.slider?.intValue ?? 8)
        for bar in 1...max {
            let next: (Byte, ChordQuality)
            if bar == max-1 {next = (Scale.getInterval(mode: modeStr, degree: 5), .dom7)}
            else if bar == max {
                next = (Scale.getInterval(mode: modeStr, degree: 1), Scale.getQuality(mode: modeStr, degree: 1))
                for musician in musicians {musician.lastBar = true}
            }
            else {next = generator.nextChord()}
            let nextInterval = next.0
            let nextQuality = next.1
            var members: [MIDI.ChordMember] = []
            for beat in 1...time.0 {
                for musician in musicians {
                    members += musician.chordMembers(bar: bar, beat: beat, root: tonic+nextInterval, quality: nextQuality)
                }
            }
            bytes += MIDI.chord(root: MIDI.Note.init(pitch: tonic+nextInterval, velocity: 0, duration: MIDI.duration(time.1) * UInt32(time.0)), members: members)
        }
        return bytes
    }
    @objc func play() {
        let content = generate()
        let file = MIDI.file(mode: .SingleTrack, contents: content)
        let data = Data(bytes: file)
        player = try? AVMIDIPlayer(data: data, soundBankURL: nil)
        player?.play()
    }
}

class Musician {
    var channel: Byte
    var time: (Int, Int)
    var lastBar = false
    var tonic: Byte
    var mode: String
    init(channel: Byte, time: (Int, Int), tonic: Byte, mode: String) {
        self.channel = channel
        self.time = time
        self.tonic = tonic
        self.mode = mode
    }
    func chordMembers(bar: Int, beat: Int, root: Byte, quality: ChordQuality) -> [MIDI.ChordMember] {
        return []
    }

    func member(pitch: MIDI.ChordMember.Pitch, velocity: Byte? = nil, duration: UInt32? = nil, beat: Int) -> MIDI.ChordMember {
        return MIDI.ChordMember(pitch: pitch, velocity: velocity, duration: duration, offset: MIDI.duration(time.1) * UInt32(beat - 1), channel: self.channel)
    }
}

class ChordalAccompaniment: Musician {
    override func chordMembers(bar: Int, beat: Int, root: Byte, quality: ChordQuality) -> [MIDI.ChordMember] {
        var members: [MIDI.ChordMember] = []
        for interval in quality.intervals {
            let velocity: Byte
            if beat == 1 {velocity = 80}
            else if beat == 1 + time.0/2 {velocity = 70}
            else {velocity = 60}
            if (!lastBar) {
                members.append(member(pitch: .Interval(interval), velocity: velocity, duration: MIDI.duration(time.1), beat: beat))
            }
            else if (lastBar && beat == 1) {
                members.append(member(pitch: .Interval(interval), velocity: velocity, beat: beat))
            }
        }
        return members
    }
}

class Bass: Musician {
    var lastRoot: Byte?
    var lastNote: Byte?
    override func chordMembers(bar: Int, beat: Int, root: Byte, quality: ChordQuality) -> [MIDI.ChordMember] {
        let pitch: Byte
        if lastBar {pitch = root}
        else if let uLastNote = lastNote, let uLastRoot = lastRoot {
            if uLastRoot == root {pitch = uLastNote}
            else {
                let diffs: [Byte] = quality.intervals.map {interval in
                    let interval_absolute: Byte = root + interval
                    return interval_absolute > uLastNote ? interval_absolute - uLastNote : uLastNote - interval_absolute
                    }.filter {$0 != 0}
                pitch = root + quality.intervals[diffs.index(of: diffs.min() ?? 0) ?? 0]
            }
        }
        else {pitch = root}
        lastRoot = root
        lastNote = pitch
        if beat != 1 {return []}
        else {return [member(pitch: .Absolute(pitch > MIDI.P8 ? pitch - MIDI.P8 : pitch), velocity: 120, beat: beat)]}
    }
}

class Melody: Musician {
    var passingTone = 0
    var ascending = false
    var startTone: Byte = 0
    var midTone: Byte = 0
    var endTone: Byte = 0
    override func chordMembers(bar: Int, beat: Int, root: Byte, quality: ChordQuality) -> [MIDI.ChordMember] {
        let ornamentChance = Int(ornament.slider?.intValue ?? 20)
        if lastBar {
            if beat != 1 {return []}
            else {
                var finalNote = root
                if percentChance(50) {finalNote += MIDI.P8}
                if percentChance(50) && finalNote > MIDI.P8 {finalNote -= MIDI.P8}
                return [member(pitch: .Absolute(finalNote), velocity: 60, beat: beat)]
            }
        }
        else if passingTone > 0 {
            if passingTone == 1 {
                passingTone = 2
                return [member(pitch: .Interval(midTone), velocity: 60, duration: MIDI.duration(time.1), beat: beat)]
            }
            else {
                passingTone = 0
                return [member(pitch: .Interval(endTone), velocity: 60, duration: MIDI.duration(time.1), beat: beat)]
            }
        }
        else if time.0 - beat >= 2 && percentChance(ornamentChance)
        {
            ascending = percentChance(50)
            let lowerToneIndex = randomInt(below: quality.intervals.count-1)
            let lowerTone = quality.intervals[lowerToneIndex]
            midTone = lowerTone + 12
            let upperTone = quality.intervals[lowerToneIndex+1]
            for tone in Scale.intervals {
                if tone > lowerTone + 1 && tone < upperTone - 1 {midTone = tone}
            }
            startTone = ascending ? lowerTone : upperTone
            endTone = ascending ? upperTone : lowerTone
            passingTone = 1
            return [member(pitch: .Interval(startTone), velocity: 80, duration: MIDI.duration(time.1), beat: beat)]
        }
        else {
            var velocity = 80 - Byte(randomInt(below: 40))
            if beat % 2 != 0 {velocity += 20}
            if beat == 1 {velocity += 20}
            if beat == time.0 / 2 + 1 {velocity += 10}
            let chance = Int(silent.slider?.intValue ?? 20)
            if percentChance(chance) {velocity = 0}
            return [member(pitch: .Interval(quality.intervals.randomElement()), velocity: velocity, duration: MIDI.duration(time.1), beat: beat)]
        }
    }
}

class Drummer: Musician {
    var type = 1
    override func chordMembers(bar: Int, beat: Int, root: Byte, quality: ChordQuality) -> [MIDI.ChordMember] {
        var pitch: Byte = MIDI.Kick1
        var velocity: Byte = 0
        if beat == 1 {
            pitch = type == 1
                ? (percentChance(50) ? MIDI.Kick1 : MIDI.Kick2)
                : (percentChance(50) ? MIDI.Crash1 : MIDI.Crash2)

            velocity = 100
        }
        else if beat == 1 + time.0 / 2 {
            pitch = percentChance(50) ? MIDI.HiHat1 : MIDI.HiHat2
            velocity = 60
        }
        else {
            pitch = type == 1
                ? (percentChance(50) ? MIDI.Snare : MIDI.Clap)
                : (percentChance(50) ? MIDI.Tambourine : MIDI.Cowbell)
            velocity = 80
        }
        return [member(pitch: .Absolute(pitch), velocity: Byte(Int(velocity) + randomInt(below: 20) * type), duration: MIDI.duration(time.1), beat: beat)]
    }
}
//: ### Play button
let player = Player()
let play = newButton(name: "🎧Click here to compose (may take a few seconds) & play", origin: CGPoint(x: -4, y: -4), target: player, action: #selector(Player.play))

