import XCTest
@testable import SVGView

class CGTests: BaseTestCase {

    func testTransformConcatenation() {
        let transform1 = CGAffineTransform(translationX: 5, y: 10)
        let transform2 = CGAffineTransform(scaleX: 2, y: 3)
        let combined = transform1.concatenating(transform2)
        
        XCTAssertEqual(combined.a, 2)
        XCTAssertEqual(combined.d, 3)
        XCTAssertEqual(combined.tx, 10)
        XCTAssertEqual(combined.ty, 30)
    }

}
