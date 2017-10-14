// some helpful functions
import Cocoa

public func percentChance(_ ch: Int) -> Bool {
    return randomInt(below: 100) < ch
}

public func randomInt(below: Int) -> Int {
    return Int(arc4random_uniform(UInt32(below)))
}

extension Array {
    public func randomElement() -> Element {
        return self[randomInt(below: self.count)]
    }
}
