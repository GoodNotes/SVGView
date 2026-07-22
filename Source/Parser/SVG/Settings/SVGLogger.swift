//
//  SVGLogger.swift
//  SVGView
//
//  Created by Yuri Strot on 26.05.2022.
//

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

public class SVGLogger {

    public static let console = SVGLogger()

    public func log(message: String) {
        print(message)
    }

    public func log(error: Error) {
        #if canImport(FoundationEssentials)
        log(message: String(describing: error))
        #else
        log(message: error.localizedDescription)
        #endif
    }

}
