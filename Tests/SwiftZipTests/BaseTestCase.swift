// SwiftZip -- Swift wrapper for libzip
//
// Copyright (c) 2019-2020 Victor Pavlychko
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

import Foundation
import XCTest
import SwiftZip

class BaseTestCase: XCTestCase {
    private static let tempRoot = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
    private static let tempDirectory = tempRoot.appendingPathComponent(UUID().uuidString, isDirectory: true)

    override class func setUp() {
        super.setUp()
        try? FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true, attributes: nil)
        print(tempDirectory)
    }

    override class func tearDown() {
        try? FileManager.default.removeItem(at: tempDirectory)
        super.tearDown()
    }

    func tempFile(type ext: String) -> URL {
        return Self.tempDirectory.appendingPathComponent(UUID().uuidString, isDirectory: false).appendingPathExtension(ext)
    }
}

class SampleTest: BaseTestCase {
    func testExample() throws {
        let archive = try ZipArchive(url: tempFile(type: "zip"), flags: [.create, .truncate])
        let source = try ZipSourceData(data: "Hello".data(using: .utf8)!)
        try archive.addFile(name: "test.txt", source: source)
        try archive.close()
    }
}
