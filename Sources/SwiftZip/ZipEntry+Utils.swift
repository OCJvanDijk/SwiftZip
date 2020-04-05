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

extension ZipEntry {
    public func data(flags: OpenFlags = [], version: ZipArchive.Version = .current, password: String? = nil) throws -> Data {
        let size = try stat().size
        var data = Data(count: Int(size))
        try data.withUnsafeMutableBytes { buffer in
            let file = try open(flags: flags, version: version, password: password)
            let read = try file.read(buf: buffer.baseAddress!, count: buffer.count)
            assert(read == buffer.count, "Failed to read \(buffer.count) bytes. Got \(read) instead.")
            file.close()
        }

        return data
    }

    @discardableResult
    public func save(to url: URL, flags: OpenFlags = [], version: ZipArchive.Version = .current, password: String? = nil, overwrite: Bool = false, progressHandler: ((Double) -> Bool)? = nil) throws -> Bool {
        guard url.isFileURL else {
            throw ZipError.unsupportedURL
        }

        let path = url.absoluteURL.path
        let fileManager = FileManager.default

        guard overwrite || !fileManager.fileExists(atPath: path) else {
            return false
        }

        let fileStat = try stat()
        let externalAttributes = try getExternalAttributes()
        var fileAttributes: [FileAttributeKey: Any] = [:]

        if externalAttributes.isSymbolicLink || externalAttributes.isDirectory {
            return false
        }

        if fileStat.valid.contains(.modificationDate) {
            fileAttributes[.modificationDate] = fileStat.modificationDate
        }

        switch externalAttributes.operatingSystem {
        case .unix,
             .macintosh,
             .macOS:
            fileAttributes[.posixPermissions] = externalAttributes.posixPermissions

        default:
            break
        }

        let file = try open(flags: flags, version: version, password: password)
        defer { file.close() }

        guard fileManager.createFile(atPath: path, contents: nil, attributes: fileAttributes) else {
            throw ZipError.createFileFailed
        }

        let fileHandle = try FileHandle(forWritingTo: url)
        defer { fileHandle.closeFile() }

        var buffer = Data(count: 64 * 1024)
        var totalReadCount: Int = 0
        while true {
            let readCount = try buffer.withUnsafeMutableBytes { buffer in
                return try file.read(buf: buffer)
            }

            guard readCount > 0 else {
                break
            }

            autoreleasepool {
                fileHandle.write(buffer.subdata(in: 0 ..< readCount))
            }

            totalReadCount += readCount

            if fileStat.valid.contains(.size), fileStat.size > 0, let progressHandler = progressHandler {
                guard progressHandler(Double(totalReadCount) / Double(fileStat.size)) else {
                    return false
                }
            }
        }

        return true
    }
}
