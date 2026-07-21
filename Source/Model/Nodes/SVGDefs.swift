#if FOUNDATION_ESSENTIALS_BUILD
import FoundationEssentials
#elseif os(WASI) || os(Linux) || os(Android)
import Foundation
#else
import SwiftUI
import Combine
#endif

public class SVGDefs: SVGGroup {}

