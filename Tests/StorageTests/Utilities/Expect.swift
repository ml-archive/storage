import XCTest

func expect<E: Error, ReturnType>(
    toThrow expectedError: E,
    file: StaticString = #file,
    line: UInt = #line,
    from closure: () throws -> ReturnType
) where E: Equatable {
    do {
        let _ = try closure()
        XCTFail("should have thrown", file: file, line: line)
    } catch let error as E {
        XCTAssertEqual(error, expectedError)
    } catch {
        XCTFail(
            "expected type \(type(of: expectedError)) got \(type(of: error))",
            file: file,
            line: line
        )
    }
}

func expectNoThrow<ReturnType>(
    file: StaticString = #file,
    line: UInt = #line,
    _ closure: () throws -> ReturnType
) {
    do {
        let _ = try closure()
    } catch {
        XCTFail("closure threw: \(error)", file: file, line: line)
    }
}

func expect<ReturnType>(
    _ closure: () throws -> ReturnType,
    file: StaticString = #file,
    line: UInt = #line,
    toReturn expectedResult: ReturnType
) where ReturnType: Equatable {
    do {
        let result = try closure()
        XCTAssertEqual(result, expectedResult, file: file, line: line)
    } catch {
        XCTFail("closure threw: \(error)", file: file, line: line)
    }
}
