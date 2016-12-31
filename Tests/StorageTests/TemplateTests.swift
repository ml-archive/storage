import XCTest

@testable import Storage

class TemplateTests: XCTestCase {
    static var allTests = [
        ("testExtractPartBasic", testExtractPartBasic),
        ("testExtractPartFailed", testExtractPartFailed),
        ("testExtractPartDoubleAlias", testExtractPartDoubleAlias),
        ("testExtractPartMatchingPrefixes", testExtractPartMatchingPrefixes),
        ("testPathPartEquatableFalse", testPathPartEquatableFalse)
    ]
    
    func testExtractPartBasic() {
        let template = "$folder/$file"
        let expected: [Template.PathPart] = [
            .alias(.folder),
            .literal("/".bytes),
            .alias(.file)
        ]
        
        expectParts(expected, fromTemplate: template)
    }
    
    func testExtractPartFailed() {
        let templateString = "$madeupAlias"
        let scanner = Scanner(templateString.bytes)
        var template = Template(scanner: scanner)
        
        expect(toThrow: Template.Error.invalidAlias("$madeupAlias")) {
            _ = try template.extractPart()
        }
    }
    
    func testExtractPartDoubleAlias() {
        let template = "$folder$file"
        let expected: [Template.PathPart] = [
            .alias(.folder),
            .alias(.file)
        ]
        
        expectParts(expected, fromTemplate: template)
    }
    
    func testExtractPartMatchingPrefixes() {
        let template = "$file$fileName$fileExtension"
        let expected: [Template.PathPart] = [
            .alias(.file),
            .alias(.fileName),
            .alias(.fileExtension)
        ]
        
        expectParts(expected, fromTemplate: template)
    }
    
    func testPathPartEquatableFalse() {
        let literalA = Template.PathPart.literal("a".bytes)
        let literalB = Template.PathPart.literal("b".bytes)
        
        let aliasFile = Template.PathPart.alias(.file)
        let aliasMime = Template.PathPart.alias(.mime)
        
        XCTAssertNotEqual(literalA, literalB)
        XCTAssertNotEqual(aliasFile, aliasMime)
        XCTAssertNotEqual(literalA, aliasMime)
    }
}

extension TemplateTests {
    func expectParts(
        _ expectedParts: [Template.PathPart],
        fromTemplate template: String,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let bytes = template.bytes
        let scanner = Scanner(bytes)
        var template = Template(scanner: scanner)
        
        for expected in expectedParts {
            var part: Template.PathPart? = nil
            
            expectNoThrow() {
                part = try template.extractPart()
            }
            
            XCTAssertNotNil(part, "should have extracted non-nil", file: file, line: line)
            XCTAssert(part! == expected, file: file, line: line)
        }
    }
}
