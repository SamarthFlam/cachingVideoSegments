import Foundation

class HLSParser {
    static func parseMasterM3U8(url: URL, completion: @escaping ([URL]) -> Void) {
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil else {
                print("Error fetching master m3u8: \(String(describing: error))")
                return
            }
            let content = String(data: data, encoding: .utf8)!
            var variantURLs: [URL] = []
            
            let lines = content.split(separator: "\n")
            for i in 0..<lines.count {
                if lines[i].contains("EXT-X-STREAM-INF") {
                    let urlString = String(lines[i + 1])
                    if let variantURL = URL(string: urlString, relativeTo: url) {
                        variantURLs.append(variantURL)
                    }
                }
            }
            completion(variantURLs)
        }.resume()
    }

    static func parseVariantM3U8(url: URL, completion: @escaping ([URL]) -> Void) {
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil else {
                print("Error fetching variant m3u8: \(String(describing: error))")
                return
            }
            let content = String(data: data, encoding: .utf8)!
            var segmentURLs: [URL] = []
            
            let lines = content.split(separator: "\n")
            for line in lines {
                if line.hasSuffix(".m4s") {
                    if let segmentURL = URL(string: String(line), relativeTo: url) {
                        segmentURLs.append(segmentURL)
                    }
                }
            }
            completion(segmentURLs)
        }.resume()
    }

    static func downloadSegments(urls: [URL], completion: @escaping ([URL: Data]) -> Void) {
        var cachedData = [URL: Data]()
        let dispatchGroup = DispatchGroup()
        
        for url in urls {
            dispatchGroup.enter()
            URLSession.shared.dataTask(with: url) { data, response, error in
                guard let data = data, error == nil else {
                    print("Error downloading segment: \(String(describing: error))")
                    dispatchGroup.leave()
                    return
                }
                cachedData[url] = data
                dispatchGroup.leave()
            }.resume()
        }
        
        dispatchGroup.notify(queue: .main) {
            completion(cachedData)
        }
    }
}
