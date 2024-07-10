//import Foundation
//
//class CachedHLSClient {
//    private let userDefaults: UserDefaults
//    private let urlSession: URLSession
//    private let urlCache: URLCache
//    
//    init(userDefaults: UserDefaults = UserDefaults.standard, urlSession: URLSession = URLSession.shared, urlCache: URLCache = URLCache.shared) {
//        print("init")
//        self.userDefaults = userDefaults
//        self.urlSession = urlSession
//        self.urlCache = urlCache
//    }
//    
//    func loadSegment(with url: URL, completion: @escaping (Data?, Error?) -> Void) {
//        print("loadsegment")
//        if let cachedData = userDefaults.data(forKey: url.absoluteString) {
//            print("cached?")
//            // Check if data is cached and return it
//            completion(cachedData, nil)
//            return
//        }
//        
//        if let cachedResponse = urlCache.cachedResponse(for: URLRequest(url: url)) {
//            print("cache response")
//            completion(cachedResponse.data, nil)
//            return
//        }
//        
//        // Data not cached, fetch from network
//        let task = urlSession.dataTask(with: url) { [weak self] data, response, error in
//            guard let self = self else { return }
//            
//            if let error = error {
//                completion(nil, error)
//                return
//            }
//            
//            guard let data = data, let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
//                completion(nil, URLError(.cannotFindHost))
//                return
//            }
//            
//            print("fetched")
//            // Cache the fetched data in UserDefaults
//            self.userDefaults.set(data, forKey: url.absoluteString)
//            
//            // Cache the fetched data in URLCache
//            if let response = response {
//                let cachedResponse = CachedURLResponse(response: response, data: data)
//                self.urlCache.storeCachedResponse(cachedResponse, for: URLRequest(url: url))
//            }
//            
//            completion(data, nil)
//        }
//        task.resume()
//    }
//}
