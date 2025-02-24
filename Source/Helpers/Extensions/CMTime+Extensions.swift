//
//  File.swift
//  
//
//  Created by Degusta Dev on 06/12/23.
//

import CoreMedia

extension CMTime {
    var displayString: String {
        let offset = TimeInterval(seconds)
        let numberOfNanosecondsFloat = (offset - TimeInterval(Int(offset))) * 1000.0
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .positional
        formatter.zeroFormattingBehavior = .pad
        formatter.allowedUnits = [.minute, .second]
        let string = String(format: "%@", formatter.string(from: offset) ?? "0:00")
        return (string.hasPrefix("0") && string.count > 4) ? String(string.dropFirst()) : string
    }
}
