/*
 This source file is part of the Swift System open source project

 Copyright (c) 2020 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
*/

import XCTest
import SystemPackage
@testable import SystemInternals

// @available...
final class MockingTest: XCTestCase {
  func testMocking() {
    XCTAssertFalse(mockingEnabled)
    MockingDriver.withMockingEnabled { driver in
      XCTAssertTrue(mockingEnabled)
      XCTAssertTrue(driver === currentMockingDriver)

      XCTAssertEqual(driver.forceErrno, .none)
      let forced = ForceErrno.always(errno: 42)
      driver.forceErrno = forced
      XCTAssertEqual(driver.forceErrno, forced)

      // Test that a nested call swaps in a new driver and restores the old one after
      MockingDriver.withMockingEnabled { nestedDriver in
        XCTAssertTrue(mockingEnabled)
        XCTAssertTrue(nestedDriver === currentMockingDriver)
        XCTAssertFalse(nestedDriver === driver)
        XCTAssertEqual(nestedDriver.forceErrno, .none)
      }

      XCTAssertTrue(mockingEnabled)
      XCTAssertEqual(driver.forceErrno, forced)
    }
    XCTAssertFalse(mockingEnabled)

    // Mocking should be enabled even if we do not refer to the driver
    MockingDriver.withMockingEnabled { _ in
      XCTAssertTrue(mockingEnabled)
    }
    XCTAssertFalse(mockingEnabled)
  }
}
