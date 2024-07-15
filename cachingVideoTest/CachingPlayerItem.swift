//import Foundation
//import AVFoundation
//
//fileprivate extension URL {
//    func withScheme(_ scheme: String) -> URL? {
//        var components = URLComponents(url: self, resolvingAgainstBaseURL: false)
//        components?.scheme = scheme
//        return components?.url
//    }
//}
//
//public enum CachingPlayerItemState {
//    case playbackBufferEmpty
//    case playbackLikelyToKeepUp
//    case none
//    case statusChanged
//}
//
//public protocol CachingPlayerItemStateDelegate: AnyObject {
//    func playerItemStateChange(_ playerItem: CachingPlayerItem, changedTo state: CachingPlayerItemState)
//}
//
//@objc public protocol CachingPlayerItemDelegate {
//    @objc optional func playerItem(_ playerItem: CachingPlayerItem, didFinishDownloadingData data: Data)
//    @objc optional func playerItem(_ playerItem: CachingPlayerItem, didDownloadBytesSoFar bytesDownloaded: Int, outOf bytesExpected: Int)
//    @objc optional func playerItemReadyToPlay(_ playerItem: CachingPlayerItem)
//    @objc optional func playerItemPlaybackStalled(_ playerItem: CachingPlayerItem)
//    @objc optional func playerItem(_ playerItem: CachingPlayerItem, downloadingFailedWith error: Error)
//}
//
//open class CachingPlayerItem: AVPlayerItem {
//    class ResourceLoaderDelegate: NSObject, AVAssetResourceLoaderDelegate, URLSessionDelegate, URLSessionDataDelegate, URLSessionTaskDelegate {
//        var playingFromData = false
//        var mimeType: String?
//        var session: URLSession?
//        public var mediaData: Data?
//        var response: URLResponse?
//        var pendingRequests = Set<AVAssetResourceLoadingRequest>()
//        private let pendingRequestsQueue = DispatchQueue(label: "CachingPlayerItem.pendingRequestsQueue")
//        weak var owner: CachingPlayerItem?
//        
//        private var cachedSegments: [URL: Data] = [:] // Cache for segments
//        private var currentSegmentUrl: URL?
//        
//        func resourceLoader(_ resourceLoader: AVAssetResourceLoader, shouldWaitForLoadingOfRequestedResource loadingRequest: AVAssetResourceLoadingRequest) -> Bool {
//            if playingFromData {
//                return false
//            } else if session == nil {
//                guard let initialUrl = owner?.url else { return false }
//                startDataRequest(with: initialUrl)
//            }
//            
//            pendingRequestsQueue.sync {
//                pendingRequests.insert(loadingRequest)
//            }
//            processPendingRequests()
//            return true
//        }
//        
//        func startDataRequest(with url: URL) {
//            if let cachedData = cachedSegments[url] {
//                mediaData = cachedData
//                processPendingRequests()
//                return
//            }
//            
//            print("Starting data request for segment: \(url.absoluteString)") // Log segment download start
//            let configuration = URLSessionConfiguration.default
//            configuration.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
//            session = URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
//            session?.dataTask(with: url).resume()
//        }
//        
//        func resourceLoader(_ resourceLoader: AVAssetResourceLoader, didCancel loadingRequest: AVAssetResourceLoadingRequest) {
//            pendingRequestsQueue.sync {
//                pendingRequests.remove(loadingRequest)
//            }
//        }
//        
//        func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
//            if mediaData == nil {
//                mediaData = Data()
//            }
//            mediaData?.append(data)
//            print("Downloading segment: \(dataTask.currentRequest?.url?.absoluteString ?? "unknown URL") - Downloaded \(mediaData!.count) bytes") // Log segment download progress
//            processPendingRequests()
//            owner?.delegate?.playerItem?(owner!, didDownloadBytesSoFar: mediaData!.count, outOf: Int(dataTask.countOfBytesExpectedToReceive))
//        }
//        
//        func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
//            completionHandler(.allow)
//            mediaData = Data()
//            self.response = response
//            print("Received response for segment: \(dataTask.currentRequest?.url?.absoluteString ?? "unknown URL")") // Log segment response
//            processPendingRequests()
//        }
//        
//        func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
//            if let errorUnwrapped = error {
//                print("Error downloading segment: \(task.currentRequest?.url?.absoluteString ?? "unknown URL") - \(errorUnwrapped.localizedDescription)") // Log segment download error
//                owner?.delegate?.playerItem?(owner!, downloadingFailedWith: errorUnwrapped)
//                return
//            }
//            
//            if let segmentUrl = currentSegmentUrl, let data = mediaData {
//                cachedSegments[segmentUrl] = data
//            }
//            
//            print("Completed downloading segment: \(task.currentRequest?.url?.absoluteString ?? "unknown URL")") // Log segment download completion
//            processPendingRequests()
//            owner?.delegate?.playerItem?(owner!, didFinishDownloadingData: mediaData!)
//        }
//        
//        func processPendingRequests() {
//            pendingRequestsQueue.sync {
//                let requestsFulfilled = Set<AVAssetResourceLoadingRequest>(pendingRequests.compactMap {
//                    self.fillInContentInformationRequest($0.contentInformationRequest)
//                    if self.haveEnoughDataToFulfillRequest($0.dataRequest!) {
//                        $0.finishLoading()
//                        return $0
//                    }
//                    return nil
//                })
//                _ = requestsFulfilled.map { self.pendingRequests.remove($0) }
//            }
//        }
//        
//        func fillInContentInformationRequest(_ contentInformationRequest: AVAssetResourceLoadingContentInformationRequest?) {
//            if playingFromData {
//                contentInformationRequest?.contentType = self.mimeType
//                contentInformationRequest?.contentLength = Int64(mediaData!.count)
//                contentInformationRequest?.isByteRangeAccessSupported = true
//                return
//            }
//            
//            guard let responseUnwrapped = response else { return }
//            contentInformationRequest?.contentType = responseUnwrapped.mimeType
//            contentInformationRequest?.contentLength = responseUnwrapped.expectedContentLength
//            contentInformationRequest?.isByteRangeAccessSupported = true
//        }
//        
//        func haveEnoughDataToFulfillRequest(_ dataRequest: AVAssetResourceLoadingDataRequest) -> Bool {
//            let requestedOffset = Int(dataRequest.requestedOffset)
//            let requestedLength = dataRequest.requestedLength
//            let currentOffset = Int(dataRequest.currentOffset)
//            
//            guard let songDataUnwrapped = mediaData, songDataUnwrapped.count > currentOffset else {
//                return false
//            }
//            
//            let bytesToRespond = min(songDataUnwrapped.count - currentOffset, requestedLength)
//            let dataToRespond = songDataUnwrapped.subdata(in: currentOffset..<(currentOffset + bytesToRespond))
//            dataRequest.respond(with: dataToRespond)
//            
//            return songDataUnwrapped.count >= requestedLength + requestedOffset
//        }
//        
//        deinit {
//            session?.invalidateAndCancel()
//        }
//    }
//    
//    fileprivate let resourceLoaderDelegate = ResourceLoaderDelegate()
//    public let url: URL
//    fileprivate let initialScheme: String?
//    fileprivate var customFileExtension: String?
//    
//    public weak var delegate: CachingPlayerItemDelegate?
//    public weak var stateDelegate: CachingPlayerItemStateDelegate?
//    
//    open func download() {
//        if resourceLoaderDelegate.session == nil {
//            resourceLoaderDelegate.startDataRequest(with: url)
//        }
//    }
//    
//    private let cachingPlayerItemScheme = "https"
//    
//    convenience init(url: URL) {
//        self.init(url: url, customFileExtension: nil)
//    }
//    
//    public init(url: URL, customFileExtension: String?) {
//        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
//              let scheme = components.scheme,
//              var urlWithCustomScheme = url.withScheme(cachingPlayerItemScheme) else {
//            fatalError("Urls without a scheme are not supported")
//        }
//        
//        self.url = url
//        self.initialScheme = scheme
//        
//        if let ext = customFileExtension {
//            urlWithCustomScheme.deletePathExtension()
//            urlWithCustomScheme.appendPathExtension(ext)
//            self.customFileExtension = ext
//        }
//        
//        let asset = AVURLAsset(url: urlWithCustomScheme)
//        asset.resourceLoader.setDelegate(resourceLoaderDelegate, queue: DispatchQueue.main)
//        super.init(asset: asset, automaticallyLoadedAssetKeys: nil)
//        
//        resourceLoaderDelegate.owner = self
//    }
//    
//    public init(data: Data, mimeType: String, fileExtension: String) {
//        self.url = URL(string: "https://cacheddata")!
//        self.initialScheme = "https"
//        
//        let asset = AVURLAsset(url: self.url)
//        asset.resourceLoader.setDelegate(resourceLoaderDelegate, queue: DispatchQueue.main)
//        super.init(asset: asset, automaticallyLoadedAssetKeys: nil)
//        
//        resourceLoaderDelegate.playingFromData = true
//        resourceLoaderDelegate.mediaData = data
//        resourceLoaderDelegate.mimeType = mimeType
//        self.customFileExtension = fileExtension
//        
//        resourceLoaderDelegate.owner = self
//    }
//    
//    open override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
//        if keyPath == "playbackBufferEmpty" {
//            stateDelegate?.playerItemStateChange(self, changedTo: .playbackBufferEmpty)
//            delegate?.playerItemPlaybackStalled?(self)
//        } else if keyPath == "playbackLikelyToKeepUp" {
//            stateDelegate?.playerItemStateChange(self, changedTo: .playbackLikelyToKeepUp)
//        } else if keyPath == "status" {
//            stateDelegate?.playerItemStateChange(self, changedTo: .statusChanged)
//        }
//    }
//    
//    deinit {
//        resourceLoaderDelegate.session?.invalidateAndCancel()
//    }
//}



//MARK: working code

//Most successful code working



//import Foundation
//import AVFoundation
//import SystemConfiguration
//
//fileprivate extension URL {
//    func withScheme(_ scheme: String) -> URL? {
//        var components = URLComponents(url: self, resolvingAgainstBaseURL: false)
//        components?.scheme = scheme
//        return components?.url
//    }
//}
//
//public enum CachingPlayerItemState {
//    case playbackBufferEmpty
//    case playbackLikelyToKeepUp
//    case none
//    case statusChanged
//}
//
//public protocol CachingPlayerItemStateDelegate: AnyObject {
//    func playerItemStateChange(_ playerItem: CachingPlayerItem, changedTo state: CachingPlayerItemState)
//}
//
//@objc public protocol CachingPlayerItemDelegate {
//    @objc optional func playerItem(_ playerItem: CachingPlayerItem, didFinishDownloadingData data: Data)
//    @objc optional func playerItem(_ playerItem: CachingPlayerItem, didDownloadBytesSoFar bytesDownloaded: Int, outOf bytesExpected: Int)
//    @objc optional func playerItemReadyToPlay(_ playerItem: CachingPlayerItem)
//    @objc optional func playerItemPlaybackStalled(_ playerItem: CachingPlayerItem)
//    @objc optional func playerItem(_ playerItem: CachingPlayerItem, downloadingFailedWith error: Error)
//}
//
//open class CachingPlayerItem: AVPlayerItem {
//    class ResourceLoaderDelegate: NSObject, AVAssetResourceLoaderDelegate, URLSessionDelegate, URLSessionDataDelegate, URLSessionTaskDelegate {
//        var playingFromData = false
//        var mimeType: String?
//        var session: URLSession?
//        public var mediaData: Data?
//        var response: URLResponse?
//        var pendingRequests = Set<AVAssetResourceLoadingRequest>()
//        private let pendingRequestsQueue = DispatchQueue(label: "CachingPlayerItem.pendingRequestsQueue")
//        weak var owner: CachingPlayerItem?
//        
//        private var cachedSegments: [URL: Data] = [:] // Cache for segments
//        private var currentSegmentUrl: URL?
//        var segmentUrls: [URL] = [] // URLs of all segments
//        
//        func resourceLoader(_ resourceLoader: AVAssetResourceLoader, shouldWaitForLoadingOfRequestedResource loadingRequest: AVAssetResourceLoadingRequest) -> Bool {
//            if playingFromData {
//                return false
//            } else if session == nil {
//                guard let initialUrl = owner?.url else { return false }
//                startDataRequest(with: initialUrl)
//            }
//            
//            pendingRequestsQueue.sync {
//                pendingRequests.insert(loadingRequest)
//            }
//            processPendingRequests()
//            return true
//        }
//        
//        func startDataRequest(with url: URL) {
//            if let cachedData = cachedSegments[url] {
//                mediaData = cachedData
//                processPendingRequests()
//                return
//            }
//            
//            guard isInternetAvailable() else {
//                print("No internet connection. Using cached data if available.")
//                processPendingRequests()
//                return
//            }
//            
//            print("Starting data request for segment: \(url.absoluteString)") // Log segment download start
//            let configuration = URLSessionConfiguration.default
//            configuration.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
//            session = URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
//            session?.dataTask(with: url).resume()
//        }
//        
//        func resourceLoader(_ resourceLoader: AVAssetResourceLoader, didCancel loadingRequest: AVAssetResourceLoadingRequest) {
//            pendingRequestsQueue.sync {
//                pendingRequests.remove(loadingRequest)
//            }
//        }
//        
//        func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
//            if mediaData == nil {
//                mediaData = Data()
//            }
//            mediaData?.append(data)
//            print("Downloading segment: \(dataTask.currentRequest?.url?.absoluteString ?? "unknown URL") - Downloaded \(mediaData!.count) bytes") // Log segment download progress
//            processPendingRequests()
//            owner?.delegate?.playerItem?(owner!, didDownloadBytesSoFar: mediaData!.count, outOf: Int(dataTask.countOfBytesExpectedToReceive))
//        }
//        
//        func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
//            completionHandler(.allow)
//            mediaData = Data()
//            self.response = response
//            print("Received response for segment: \(dataTask.currentRequest?.url?.absoluteString ?? "unknown URL")") // Log segment response
//            processPendingRequests()
//        }
//        
//        func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
//            if let errorUnwrapped = error {
//                print("Error downloading segment: \(task.currentRequest?.url?.absoluteString ?? "unknown URL") - \(errorUnwrapped.localizedDescription)") // Log segment download error
//                owner?.delegate?.playerItem?(owner!, downloadingFailedWith: errorUnwrapped)
//                return
//            }
//            
//            if let segmentUrl = currentSegmentUrl, let data = mediaData {
//                cachedSegments[segmentUrl] = data
//            }
//            
//            print("Completed downloading segment: \(task.currentRequest?.url?.absoluteString ?? "unknown URL")") // Log segment download completion
//            
//            // Download next segment if available
//            if !segmentUrls.isEmpty {
//                let nextSegmentUrl = segmentUrls.removeFirst()
//                startDataRequest(with: nextSegmentUrl)
//            }
//            
//            processPendingRequests()
//            owner?.delegate?.playerItem?(owner!, didFinishDownloadingData: mediaData!)
//        }
//        
//        func processPendingRequests() {
//            pendingRequestsQueue.sync {
//                let requestsFulfilled = Set<AVAssetResourceLoadingRequest>(pendingRequests.compactMap {
//                    self.fillInContentInformationRequest($0.contentInformationRequest)
//                    if self.haveEnoughDataToFulfillRequest($0.dataRequest!) {
//                        $0.finishLoading()
//                        return $0
//                    }
//                    return nil
//                })
//                _ = requestsFulfilled.map { self.pendingRequests.remove($0) }
//            }
//        }
//        
//        func fillInContentInformationRequest(_ contentInformationRequest: AVAssetResourceLoadingContentInformationRequest?) {
//            if playingFromData {
//                contentInformationRequest?.contentType = self.mimeType
//                contentInformationRequest?.contentLength = Int64(mediaData!.count)
//                contentInformationRequest?.isByteRangeAccessSupported = true
//                return
//            }
//            
//            guard let responseUnwrapped = response else { return }
//            contentInformationRequest?.contentType = responseUnwrapped.mimeType
//            contentInformationRequest?.contentLength = responseUnwrapped.expectedContentLength
//            contentInformationRequest?.isByteRangeAccessSupported = true
//        }
//        
//        func haveEnoughDataToFulfillRequest(_ dataRequest: AVAssetResourceLoadingDataRequest) -> Bool {
//            let requestedOffset = Int(dataRequest.requestedOffset)
//            let requestedLength = dataRequest.requestedLength
//            let currentOffset = Int(dataRequest.currentOffset)
//            
//            guard let songDataUnwrapped = mediaData, songDataUnwrapped.count > currentOffset else {
//                return false
//            }
//            
//            let bytesToRespond = min(songDataUnwrapped.count - currentOffset, requestedLength)
//            let dataToRespond = songDataUnwrapped.subdata(in: currentOffset..<(currentOffset + bytesToRespond))
//            dataRequest.respond(with: dataToRespond)
//            
//            return songDataUnwrapped.count >= requestedLength + requestedOffset
//        }
//        
//        deinit {
//            session?.invalidateAndCancel()
//        }
//        
//        // Reachability check
//        private func isInternetAvailable() -> Bool {
//            var zeroAddress = sockaddr_in()
//            zeroAddress.sin_len = UInt8(MemoryLayout<sockaddr_in>.size)
//            zeroAddress.sin_family = sa_family_t(AF_INET)
//            
//            let defaultRouteReachability = withUnsafePointer(to: &zeroAddress) {
//                $0.withMemoryRebound(to: sockaddr.self, capacity: 1) { zeroSockAddress in
//                    SCNetworkReachabilityCreateWithAddress(nil, zeroSockAddress)
//                }
//            }
//            
//            var flags: SCNetworkReachabilityFlags = []
//            if !SCNetworkReachabilityGetFlags(defaultRouteReachability!, &flags) {
//                return false
//            }
//            let isReachable = flags.contains(.reachable)
//            let needsConnection = flags.contains(.connectionRequired)
//            return (isReachable && !needsConnection)
//        }
//    }
//    
//    fileprivate let resourceLoaderDelegate = ResourceLoaderDelegate()
//    public let url: URL
//    fileprivate let initialScheme: String?
//    fileprivate var customFileExtension: String?
//    
//    public weak var delegate: CachingPlayerItemDelegate?
//    public weak var stateDelegate: CachingPlayerItemStateDelegate?
//    
//    open func download() {
//        if resourceLoaderDelegate.session == nil {
//            resourceLoaderDelegate.startDataRequest(with: url)
//        }
//    }
//    
//    private let cachingPlayerItemScheme = "https"
//    
//    convenience init(url: URL) {
//        self.init(url: url, customFileExtension: nil)
//    }
//    
//    public init(url: URL, customFileExtension: String?) {
//        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
//              let scheme = components.scheme,
//              var urlWithCustomScheme = url.withScheme(cachingPlayerItemScheme) else {
//            fatalError("Urls without a scheme are not supported")
//        }
//        
//        self.url = url
//        self.initialScheme = scheme
//        
//        if let ext = customFileExtension {
//            urlWithCustomScheme.deletePathExtension()
//            urlWithCustomScheme.appendPathExtension(ext)
//        }
//        
//        let asset = AVURLAsset(url: urlWithCustomScheme)
//        asset.resourceLoader.setDelegate(resourceLoaderDelegate, queue: .main)
//        
//        self.customFileExtension = customFileExtension
//        super.init(asset: asset, automaticallyLoadedAssetKeys: nil)
//        
//        resourceLoaderDelegate.owner = self
//        
//        addObserver(self, forKeyPath: "status", options: .new, context: nil)
//        addObserver(self, forKeyPath: "playbackBufferEmpty", options: .new, context: nil)
//        addObserver(self, forKeyPath: "playbackLikelyToKeepUp", options: .new, context: nil)
//    }
//    
//    override open func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
//        if keyPath == "playbackBufferEmpty" {
//            stateDelegate?.playerItemStateChange(self, changedTo: .playbackBufferEmpty)
//            delegate?.playerItemPlaybackStalled?(self)
//        } else if keyPath == "playbackLikelyToKeepUp" {
//            stateDelegate?.playerItemStateChange(self, changedTo: .playbackLikelyToKeepUp)
//        } else if keyPath == "status" {
//            stateDelegate?.playerItemStateChange(self, changedTo: .statusChanged)
//        }
//    }
//    
//    deinit {
//        resourceLoaderDelegate.session?.invalidateAndCancel()
//    }
//    
//    func parseM3U8Playlist(from data: Data, baseUrl: URL) -> [URL]? {
//        guard let playlistString = String(data: data, encoding: .utf8) else { return nil }
//        let lines = playlistString.components(separatedBy: .newlines)
//        var segmentURLs = [URL]()
//        
//        for line in lines {
//            if line.hasSuffix(".m4s") { // Typically HLS segments end with .ts
//                if let url = URL(string: line, relativeTo: baseUrl) {
//                    segmentURLs.append(url)
//                }
//            }
//        }
//        return segmentURLs
//    }
//    
//    func fetchAllSegments(from playlistURL: URL) {
//        let task = URLSession.shared.dataTask(with: playlistURL) { data, response, error in
//            guard let data = data, error == nil else {
//                print("Failed to download playlist: \(error?.localizedDescription ?? "No error description")")
//                return
//            }
//            
//            if let segmentURLs = self.parseM3U8Playlist(from: data, baseUrl: playlistURL) {
//                self.resourceLoaderDelegate.segmentUrls = segmentURLs
//                if let firstSegment = segmentURLs.first {
//                    self.resourceLoaderDelegate.startDataRequest(with: firstSegment)
//                }
//            }
//        }
//        task.resume()
//    }
//}


// most successful code working






//import Foundation
//import AVFoundation
//
//fileprivate extension URL {
//    func withScheme(_ scheme: String) -> URL? {
//        var components = URLComponents(url: self, resolvingAgainstBaseURL: false)
//        components?.scheme = scheme
//        return components?.url
//    }
//}
//
//public enum CachingPlayerItemState {
//    case playbackBufferEmpty
//    case playbackLikelyToKeepUp
//    case none
//    case statusChanged
//}
//
//public protocol CachingPlayerItemStateDelegate: AnyObject {
//    func playerItemStateChange(_ playerItem: CachingPlayerItem, changedTo state: CachingPlayerItemState)
//}
//
//@objc public protocol CachingPlayerItemDelegate {
//    @objc optional func playerItem(_ playerItem: CachingPlayerItem, didFinishDownloadingData data: Data)
//    @objc optional func playerItem(_ playerItem: CachingPlayerItem, didDownloadBytesSoFar bytesDownloaded: Int, outOf bytesExpected: Int)
//    @objc optional func playerItemReadyToPlay(_ playerItem: CachingPlayerItem)
//    @objc optional func playerItemPlaybackStalled(_ playerItem: CachingPlayerItem)
//    @objc optional func playerItem(_ playerItem: CachingPlayerItem, downloadingFailedWith error: Error)
//}
//
//open class CachingPlayerItem: AVPlayerItem {
//    class ResourceLoaderDelegate: NSObject, AVAssetResourceLoaderDelegate, URLSessionDelegate, URLSessionDataDelegate, URLSessionTaskDelegate {
//        var playingFromData = false
//        var mimeType: String?
//        var session: URLSession?
//        public var mediaData: Data?
//        var response: URLResponse?
//        var pendingRequests = Set<AVAssetResourceLoadingRequest>()
//        private let pendingRequestsQueue = DispatchQueue(label: "CachingPlayerItem.pendingRequestsQueue")
//        weak var owner: CachingPlayerItem?
//        
//        private var cachedSegments: [URL: Data] = [:] // Cache for segments
//        private var currentSegmentUrl: URL?
//        var segmentUrls: [URL] = [] // URLs of all segments
//        
//        func resourceLoader(_ resourceLoader: AVAssetResourceLoader, shouldWaitForLoadingOfRequestedResource loadingRequest: AVAssetResourceLoadingRequest) -> Bool {
//            if playingFromData {
//                return false
//            } else if session == nil {
//                guard let initialUrl = owner?.url else { return false }
//                startDataRequest(with: initialUrl)
//            }
//            
//            pendingRequestsQueue.sync {
//                pendingRequests.insert(loadingRequest)
//            }
//            processPendingRequests()
//            return true
//        }
//        
//        func startDataRequest(with url: URL) {
//            if let cachedData = cachedSegments[url] {
//                mediaData = cachedData
//                processPendingRequests()
//                return
//            }
//            
//            print("Starting data request for segment: \(url.absoluteString)") // Log segment download start
//            let configuration = URLSessionConfiguration.default
//            configuration.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
//            session = URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
//            session?.dataTask(with: url).resume()
//        }
//        
//        func resourceLoader(_ resourceLoader: AVAssetResourceLoader, didCancel loadingRequest: AVAssetResourceLoadingRequest) {
//            pendingRequestsQueue.sync {
//                pendingRequests.remove(loadingRequest)
//            }
//        }
//        
//        func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
//            if mediaData == nil {
//                mediaData = Data()
//            }
//            mediaData?.append(data)
//            print("Downloading segment: \(dataTask.currentRequest?.url?.absoluteString ?? "unknown URL") - Downloaded \(mediaData!.count) bytes") // Log segment download progress
//            processPendingRequests()
//            owner?.delegate?.playerItem?(owner!, didDownloadBytesSoFar: mediaData!.count, outOf: Int(dataTask.countOfBytesExpectedToReceive))
//        }
//        
//        func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
//            completionHandler(.allow)
//            mediaData = Data()
//            self.response = response
//            print("Received response for segment: \(dataTask.currentRequest?.url?.absoluteString ?? "unknown URL")") // Log segment response
//            processPendingRequests()
//        }
//        
//        func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
//            if let errorUnwrapped = error {
//                print("Error downloading segment: \(task.currentRequest?.url?.absoluteString ?? "unknown URL") - \(errorUnwrapped.localizedDescription)") // Log segment download error
//                owner?.delegate?.playerItem?(owner!, downloadingFailedWith: errorUnwrapped)
//                return
//            }
//            
//            if let segmentUrl = currentSegmentUrl, let data = mediaData {
//                cachedSegments[segmentUrl] = data
//            }
//            
//            print("Completed downloading segment: \(task.currentRequest?.url?.absoluteString ?? "unknown URL")") // Log segment download completion
//            
//            // Download next segment if available
//            if !segmentUrls.isEmpty {
//                let nextSegmentUrl = segmentUrls.removeFirst()
//                startDataRequest(with: nextSegmentUrl)
//            }
//            
//            processPendingRequests()
//            owner?.delegate?.playerItem?(owner!, didFinishDownloadingData: mediaData!)
//        }
//        
//        func processPendingRequests() {
//            pendingRequestsQueue.sync {
//                let requestsFulfilled = Set<AVAssetResourceLoadingRequest>(pendingRequests.compactMap {
//                    self.fillInContentInformationRequest($0.contentInformationRequest)
//                    if self.haveEnoughDataToFulfillRequest($0.dataRequest!) {
//                        $0.finishLoading()
//                        return $0
//                    }
//                    return nil
//                })
//                _ = requestsFulfilled.map { self.pendingRequests.remove($0) }
//            }
//        }
//        
//        func fillInContentInformationRequest(_ contentInformationRequest: AVAssetResourceLoadingContentInformationRequest?) {
//            if playingFromData {
//                contentInformationRequest?.contentType = self.mimeType
//                contentInformationRequest?.contentLength = Int64(mediaData!.count)
//                contentInformationRequest?.isByteRangeAccessSupported = true
//                return
//            }
//            
//            guard let responseUnwrapped = response else { return }
//            contentInformationRequest?.contentType = responseUnwrapped.mimeType
//            contentInformationRequest?.contentLength = responseUnwrapped.expectedContentLength
//            contentInformationRequest?.isByteRangeAccessSupported = true
//        }
//        
//        func haveEnoughDataToFulfillRequest(_ dataRequest: AVAssetResourceLoadingDataRequest) -> Bool {
//            let requestedOffset = Int(dataRequest.requestedOffset)
//            let requestedLength = dataRequest.requestedLength
//            let currentOffset = Int(dataRequest.currentOffset)
//            
//            guard let songDataUnwrapped = mediaData, songDataUnwrapped.count > currentOffset else {
//                return false
//            }
//            
//            let bytesToRespond = min(songDataUnwrapped.count - currentOffset, requestedLength)
//            let dataToRespond = songDataUnwrapped.subdata(in: currentOffset..<(currentOffset + bytesToRespond))
//            dataRequest.respond(with: dataToRespond)
//            
//            return songDataUnwrapped.count >= requestedLength + requestedOffset
//        }
//        
//        deinit {
//            session?.invalidateAndCancel()
//        }
//    }
//    
//    fileprivate let resourceLoaderDelegate = ResourceLoaderDelegate()
//    public let url: URL
//    fileprivate let initialScheme: String?
//    fileprivate var customFileExtension: String?
//    private var resolution: String
//    
//    public weak var delegate: CachingPlayerItemDelegate?
//    public weak var stateDelegate: CachingPlayerItemStateDelegate?
//    
//    open func download() {
//        if resourceLoaderDelegate.session == nil {
//            resourceLoaderDelegate.startDataRequest(with: url)
//        }
//    }
//    
//    private let cachingPlayerItemScheme = "https"
//    
//    convenience init(url: URL, resolution: String) {
//        self.init(url: url, resolution: resolution, customFileExtension: nil)
//    }
//    
//    public init(url: URL, resolution: String, customFileExtension: String?) {
//        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
//              let scheme = components.scheme,
//              var urlWithCustomScheme = url.withScheme(cachingPlayerItemScheme) else {
//            fatalError("Urls without a scheme are not supported")
//        }
//        
//        self.url = url
//        self.initialScheme = scheme
//        self.resolution = resolution
//        
//        if let ext = customFileExtension {
//            urlWithCustomScheme.deletePathExtension()
//            urlWithCustomScheme.appendPathExtension(ext)
//        }
//        
//        let asset = AVURLAsset(url: urlWithCustomScheme)
//        asset.resourceLoader.setDelegate(resourceLoaderDelegate, queue: .main)
//        
//        self.customFileExtension = customFileExtension
//        super.init(asset: asset, automaticallyLoadedAssetKeys: nil)
//        
//        resourceLoaderDelegate.owner = self
//        
//        // Download the .m3u8 file and parse segments
//        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
//            guard let self = self, let data = data, error == nil else { return }
//            
//            if let segmentUrls = self.parseM3U8Playlist(from: data) {
//                self.resourceLoaderDelegate.segmentUrls = segmentUrls
//                if let firstSegmentUrl = segmentUrls.first {
//                    self.resourceLoaderDelegate.startDataRequest(with: self.modifySegmentUrl(for: firstSegmentUrl))
//                }
//            }
//        }.resume()
//        
//        addObserver(self, forKeyPath: "status", options: .new, context: nil)
//        addObserver(self, forKeyPath: "playbackBufferEmpty", options: .new, context: nil)
//        addObserver(self, forKeyPath: "playbackLikelyToKeepUp", options: .new, context: nil)
//    }
//    
//    override open func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
//        if keyPath == "playbackBufferEmpty" {
//            stateDelegate?.playerItemStateChange(self, changedTo: .playbackBufferEmpty)
//            delegate?.playerItemPlaybackStalled?(self)
//        } else if keyPath == "playbackLikelyToKeepUp" {
//            stateDelegate?.playerItemStateChange(self, changedTo: .playbackLikelyToKeepUp)
//        } else if keyPath == "status" {
//            stateDelegate?.playerItemStateChange(self, changedTo: .statusChanged)
//        }
//    }
//    
//    deinit {
//        resourceLoaderDelegate.session?.invalidateAndCancel()
//    }
//    
//    func parseM3U8Playlist(from data: Data) -> [URL]? {
//        guard let playlistString = String(data: data, encoding: .utf8) else { return nil }
//        let lines = playlistString.components(separatedBy: .newlines)
//        var segmentURLs = [URL]()
//        
//        for line in lines {
//            if line.hasSuffix(".m4s") { // Typically HLS segments end with .ts or .m4s
//                if let url = URL(string: line) {
//                    segmentURLs.append(url)
//                }
//            }
//        }
//        return segmentURLs
//    }
//    
//    func modifySegmentUrl(for url: URL) -> URL {
//        var modifiedUrl = url
//        modifiedUrl.deleteLastPathComponent()
//        modifiedUrl.appendPathComponent(resolution)
//        modifiedUrl.appendPathComponent(url.lastPathComponent)
//        return modifiedUrl
//    }
//}



//import Foundation
//import AVFoundation
//import SystemConfiguration
//
//fileprivate extension URL {
//    func withScheme(_ scheme: String) -> URL? {
//        var components = URLComponents(url: self, resolvingAgainstBaseURL: false)
//        components?.scheme = scheme
//        return components?.url
//    }
//}
//
//public enum CachingPlayerItemState {
//    case playbackBufferEmpty
//    case playbackLikelyToKeepUp
//    case none
//    case statusChanged
//}
//
//public protocol CachingPlayerItemStateDelegate: AnyObject {
//    func playerItemStateChange(_ playerItem: CachingPlayerItem, changedTo state: CachingPlayerItemState)
//}
//
//@objc public protocol CachingPlayerItemDelegate {
//    @objc optional func playerItem(_ playerItem: CachingPlayerItem, didFinishDownloadingData data: Data)
//    @objc optional func playerItem(_ playerItem: CachingPlayerItem, didDownloadBytesSoFar bytesDownloaded: Int, outOf bytesExpected: Int)
//    @objc optional func playerItemReadyToPlay(_ playerItem: CachingPlayerItem)
//    @objc optional func playerItemPlaybackStalled(_ playerItem: CachingPlayerItem)
//    @objc optional func playerItem(_ playerItem: CachingPlayerItem, downloadingFailedWith error: Error)
//}
//
//open class CachingPlayerItem: AVPlayerItem {
//    class ResourceLoaderDelegate: NSObject, AVAssetResourceLoaderDelegate, URLSessionDelegate, URLSessionDataDelegate, URLSessionTaskDelegate {
//        var playingFromData = false
//        var mimeType: String?
//        var session: URLSession?
//        public var mediaData: Data?
//        var response: URLResponse?
//        var pendingRequests = Set<AVAssetResourceLoadingRequest>()
//        private let pendingRequestsQueue = DispatchQueue(label: "CachingPlayerItem.pendingRequestsQueue")
//        weak var owner: CachingPlayerItem?
//        
//        private var cachedSegments: [URL: Data] = [:] // Cache for segments
//        private var currentSegmentUrl: URL?
//        var segmentUrls: [URL] = [] // URLs of all segments
//        
//        func resourceLoader(_ resourceLoader: AVAssetResourceLoader, shouldWaitForLoadingOfRequestedResource loadingRequest: AVAssetResourceLoadingRequest) -> Bool {
//            if playingFromData {
//                return false
//            } else if session == nil {
//                guard let initialUrl = owner?.url else { return false }
//                startDataRequest(with: initialUrl)
//            }
//            
//            pendingRequestsQueue.sync {
//                pendingRequests.insert(loadingRequest)
//            }
//            processPendingRequests()
//            return true
//        }
//        
//        func startDataRequest(with url: URL) {
//            if let cachedData = cachedSegments[url] {
//                mediaData = cachedData
//                processPendingRequests()
//                return
//            }
//            
//            guard isInternetAvailable() else {
//                print("No internet connection. Using cached data if available.")
//                processPendingRequests()
//                return
//            }
//            
//            print("Starting data request for segment: \(url.absoluteString)") // Log segment download start
//            let configuration = URLSessionConfiguration.default
//            configuration.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
//            session = URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
//            session?.dataTask(with: url).resume()
//        }
//        
//        func resourceLoader(_ resourceLoader: AVAssetResourceLoader, didCancel loadingRequest: AVAssetResourceLoadingRequest) {
//            pendingRequestsQueue.sync {
//                pendingRequests.remove(loadingRequest)
//            }
//        }
//        
//        func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
//            if mediaData == nil {
//                mediaData = Data()
//            }
//            mediaData?.append(data)
//            print("Downloading segment: \(dataTask.currentRequest?.url?.absoluteString ?? "unknown URL") - Downloaded \(mediaData!.count) bytes") // Log segment download progress
//            processPendingRequests()
//            owner?.delegate?.playerItem?(owner!, didDownloadBytesSoFar: mediaData!.count, outOf: Int(dataTask.countOfBytesExpectedToReceive))
//            
//            // Log the file path where the segment is saved locally
//            logFilePath(for: dataTask.currentRequest?.url)
//        }
//        
//        func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
//            completionHandler(.allow)
//            mediaData = Data()
//            self.response = response
//            print("Received response for segment: \(dataTask.currentRequest?.url?.absoluteString ?? "unknown URL")") // Log segment response
//            processPendingRequests()
//        }
//            
//        private func logAllFilesInDocumentsDirectory() {
//            let fileManager = FileManager.default
//            guard let documentsDirectoryURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
//                print("Documents directory not found.")
//                return
//            }
//            
//            do {
//                let fileURLs = try fileManager.contentsOfDirectory(at: documentsDirectoryURL, includingPropertiesForKeys: nil)
//                print("Files in directory \(documentsDirectoryURL.path):")
//                for fileURL in fileURLs {
//                    print(fileURL.path) // Print the full path of each file
//                }
//            } catch {
//                print("Error while listing files in directory: \(error.localizedDescription)")
//            }
//        }
//
//        
//        func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
//            if let errorUnwrapped = error {
//                print("Error downloading segment: \(task.currentRequest?.url?.absoluteString ?? "unknown URL") - \(errorUnwrapped.localizedDescription)") // Log segment download error
//                owner?.delegate?.playerItem?(owner!, downloadingFailedWith: errorUnwrapped)
//                return
//            }
//            
//            if let segmentUrl = currentSegmentUrl, let data = mediaData {
//                cachedSegments[segmentUrl] = data
//            }
//            
//            print("Completed downloading segment: \(task.currentRequest?.url?.absoluteString ?? "unknown URL")") // Log segment download completion
//            
//            // Log the file path where the segment is saved locally
//            logFilePath(for: task.currentRequest?.url)
//            
//            // Download next segment if available
//            if !segmentUrls.isEmpty {
//                let nextSegmentUrl = segmentUrls.removeFirst()
//                startDataRequest(with: nextSegmentUrl)
//            } else {
//                logAllFilesInDocumentsDirectory()
//            }
//            
//            processPendingRequests()
//            owner?.delegate?.playerItem?(owner!, didFinishDownloadingData: mediaData!)
//        }
//        
//        func processPendingRequests() {
//            pendingRequestsQueue.sync {
//                let requestsFulfilled = Set<AVAssetResourceLoadingRequest>(pendingRequests.compactMap {
//                    self.fillInContentInformationRequest($0.contentInformationRequest)
//                    if self.haveEnoughDataToFulfillRequest($0.dataRequest!) {
//                        $0.finishLoading()
//                        return $0
//                    }
//                    return nil
//                })
//                _ = requestsFulfilled.map { self.pendingRequests.remove($0) }
//            }
//        }
//        
//        func fillInContentInformationRequest(_ contentInformationRequest: AVAssetResourceLoadingContentInformationRequest?) {
//            if playingFromData {
//                contentInformationRequest?.contentType = self.mimeType
//                contentInformationRequest?.contentLength = Int64(mediaData!.count)
//                contentInformationRequest?.isByteRangeAccessSupported = true
//                return
//            }
//            
//            guard let responseUnwrapped = response else { return }
//            contentInformationRequest?.contentType = responseUnwrapped.mimeType
//            contentInformationRequest?.contentLength = responseUnwrapped.expectedContentLength
//            contentInformationRequest?.isByteRangeAccessSupported = true
//        }
//        
//        func haveEnoughDataToFulfillRequest(_ dataRequest: AVAssetResourceLoadingDataRequest) -> Bool {
//            let requestedOffset = Int(dataRequest.requestedOffset)
//            let requestedLength = dataRequest.requestedLength
//            let currentOffset = Int(dataRequest.currentOffset)
//            
//            guard let songDataUnwrapped = mediaData, songDataUnwrapped.count > currentOffset else {
//                return false
//            }
//            
//            let bytesToRespond = min(songDataUnwrapped.count - currentOffset, requestedLength)
//            let dataToRespond = songDataUnwrapped.subdata(in: currentOffset..<(currentOffset + bytesToRespond))
//            dataRequest.respond(with: dataToRespond)
//            
//            return songDataUnwrapped.count >= requestedLength + requestedOffset
//        }
//        
//        deinit {
//            session?.invalidateAndCancel()
//        }
//        
//        // Reachability check
//        private func isInternetAvailable() -> Bool {
//            var zeroAddress = sockaddr_in()
//            zeroAddress.sin_len = UInt8(MemoryLayout<sockaddr_in>.size)
//            zeroAddress.sin_family = sa_family_t(AF_INET)
//            
//            let defaultRouteReachability = withUnsafePointer(to: &zeroAddress) {
//                $0.withMemoryRebound(to: sockaddr.self, capacity: 1) { zeroSockAddress in
//                    SCNetworkReachabilityCreateWithAddress(nil, zeroSockAddress)
//                }
//            }
//            
//            var flags: SCNetworkReachabilityFlags = []
//            if !SCNetworkReachabilityGetFlags(defaultRouteReachability!, &flags) {
//                return false
//            }
//            let isReachable = flags.contains(.reachable)
//            let needsConnection = flags.contains(.connectionRequired)
//            return (isReachable && !needsConnection)
//        }
//        
//        // Function to get the documents directory path
//        private func documentsDirectory() -> URL? {
//            return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
//        }
//        
//        // Function to construct the file URL for a segment with resolution directory
//        private func localFileURL(for url: URL?) -> URL? {
//            guard let url = url, let documentsDirectory = documentsDirectory() else { return nil }
//            
//            // Extract resolution from URL
//            let components = url.pathComponents
//            guard components.count >= 2 else { return nil } // Ensure the URL has enough components
//            
//            let resolution = components[components.count - 2] // Assuming resolution is second last component
//            let fileName = url.lastPathComponent
//            
//            // Construct directory path with resolution and file name
//            let resolutionDirectory = documentsDirectory.appendingPathComponent(resolution, isDirectory: true)
//            let fileURL = resolutionDirectory.appendingPathComponent(fileName)
//            
//            return fileURL
//        }
//        
//        // Function to log the directory and file path
//        private func logFilePath(for url: URL?) {
//            guard let fileURL = localFileURL(for: url) else {
//                print("Failed to get local file URL for segment: \(url?.absoluteString ?? "Unknown URL")")
//                return
//            }
//            print("Downloaded segment URL: \(url?.absoluteString ?? "Unknown URL")")
//            print("Saved to file path: \(fileURL.path)")
//        }
//    }
//    
//    fileprivate let resourceLoaderDelegate = ResourceLoaderDelegate()
//    public let url: URL
//    fileprivate let initialScheme: String?
//    fileprivate var customFileExtension: String?
//    
//    public weak var delegate: CachingPlayerItemDelegate?
//    public weak var stateDelegate: CachingPlayerItemStateDelegate?
//    
//    open func download() {
//        if resourceLoaderDelegate.session == nil {
//            resourceLoaderDelegate.startDataRequest(with: url)
//        }
//    }
//    
//    private let cachingPlayerItemScheme = "https"
//    
//    convenience init(url: URL) {
//        self.init(url: url, customFileExtension: nil)
//    }
//    
//    public init(url: URL, customFileExtension: String?) {
//        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
//              let scheme = components.scheme,
//              var urlWithCustomScheme = url.withScheme(cachingPlayerItemScheme) else {
//            fatalError("Urls without a scheme are not supported")
//        }
//        
//        self.url = url
//        self.initialScheme = scheme
//        
//        if let ext = customFileExtension {
//            urlWithCustomScheme.deletePathExtension()
//            urlWithCustomScheme.appendPathExtension(ext)
//        }
//        
//        let asset = AVURLAsset(url: urlWithCustomScheme)
//        asset.resourceLoader.setDelegate(resourceLoaderDelegate, queue: .main)
//        
//        self.customFileExtension = customFileExtension
//        super.init(asset: asset, automaticallyLoadedAssetKeys: nil)
//        
//        resourceLoaderDelegate.owner = self
//        
//        addObserver(self, forKeyPath: "status", options: .new, context: nil)
//        addObserver(self, forKeyPath: "playbackBufferEmpty", options: .new, context: nil)
//        addObserver(self, forKeyPath: "playbackLikelyToKeepUp", options: .new, context: nil)
//    }
//    
//    override open func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
//        if keyPath == "playbackBufferEmpty" {
//            stateDelegate?.playerItemStateChange(self, changedTo: .playbackBufferEmpty)
//            delegate?.playerItemPlaybackStalled?(self)
//        } else if keyPath == "playbackLikelyToKeepUp" {
//            stateDelegate?.playerItemStateChange(self, changedTo: .playbackLikelyToKeepUp)
//        } else if keyPath == "status" {
//            stateDelegate?.playerItemStateChange(self, changedTo: .statusChanged)
//        }
//    }
//    
//    deinit {
//        resourceLoaderDelegate.session?.invalidateAndCancel()
//    }
//    
//    func parseM3U8Playlist(from data: Data, baseUrl: URL) -> [URL]? {
//        guard let playlistString = String(data: data, encoding: .utf8) else { return nil }
//        let lines = playlistString.components(separatedBy: .newlines)
//        var segmentURLs = [URL]()
//        
//        for line in lines {
//            if line.hasSuffix(".m4s") { // Typically HLS segments end with .ts
//                if let url = URL(string: line, relativeTo: baseUrl) {
//                    segmentURLs.append(url)
//                }
//            }
//        }
//        return segmentURLs
//    }
//    
//    func fetchAllSegments(from playlistURL: URL) {
//        let task = URLSession.shared.dataTask(with: playlistURL) { data, response, error in
//            guard let data = data, error == nil else {
//                print("Failed to download playlist: \(error?.localizedDescription ?? "No error description")")
//                return
//            }
//            
//            if let segmentURLs = self.parseM3U8Playlist(from: data, baseUrl: playlistURL) {
//                self.resourceLoaderDelegate.segmentUrls = segmentURLs
//                if let firstSegment = segmentURLs.first {
//                    self.resourceLoaderDelegate.startDataRequest(with: firstSegment)
//                }
//            }
//        }
//        task.resume()
//    }
//}




//import Foundation
//import AVFoundation
//import SystemConfiguration
//
//fileprivate extension URL {
//    func withScheme(_ scheme: String) -> URL? {
//        var components = URLComponents(url: self, resolvingAgainstBaseURL: false)
//        components?.scheme = scheme
//        return components?.url
//    }
//}
//
//public enum CachingPlayerItemState {
//    case playbackBufferEmpty
//    case playbackLikelyToKeepUp
//    case none
//    case statusChanged
//}
//
//public protocol CachingPlayerItemStateDelegate: AnyObject {
//    func playerItemStateChange(_ playerItem: CachingPlayerItem, changedTo state: CachingPlayerItemState)
//}
//
//@objc public protocol CachingPlayerItemDelegate {
//    @objc optional func playerItem(_ playerItem: CachingPlayerItem, didFinishDownloadingData data: Data)
//    @objc optional func playerItem(_ playerItem: CachingPlayerItem, didDownloadBytesSoFar bytesDownloaded: Int, outOf bytesExpected: Int)
//    @objc optional func playerItemReadyToPlay(_ playerItem: CachingPlayerItem)
//    @objc optional func playerItemPlaybackStalled(_ playerItem: CachingPlayerItem)
//    @objc optional func playerItem(_ playerItem: CachingPlayerItem, downloadingFailedWith error: Error)
//}
//
//open class CachingPlayerItem: AVPlayerItem {
//    class ResourceLoaderDelegate: NSObject, AVAssetResourceLoaderDelegate, URLSessionDelegate, URLSessionDataDelegate, URLSessionTaskDelegate {
//        var playingFromData = false
//        var mimeType: String?
//        var session: URLSession?
//        public var mediaData: Data?
//        var response: URLResponse?
//        var pendingRequests = Set<AVAssetResourceLoadingRequest>()
//        let pendingRequestsQueue = DispatchQueue(label: "CachingPlayerItem.pendingRequestsQueue")
//        weak var owner: CachingPlayerItem?
//
//        private var cachedSegments: [URL: Data] = [:] // Cache for segments
//        private var currentSegmentUrl: URL?
//        var segmentUrls: [URL] = [] // URLs of all segments
//
//        func resourceLoader(_ resourceLoader: AVAssetResourceLoader, shouldWaitForLoadingOfRequestedResource loadingRequest: AVAssetResourceLoadingRequest) -> Bool {
//            if playingFromData {
//                return false
//            } else if session == nil {
//                guard let initialUrl = owner?.url else { return false }
//                startDataRequest(with: initialUrl)
//            }
//
//            pendingRequestsQueue.sync {
//                pendingRequests.insert(loadingRequest)
//            }
//            processPendingRequests()
//            return true
//        }
//
//        func startDataRequest(with url: URL) {
//            if let cachedData = cachedSegments[url] {
//                mediaData = cachedData
//                processPendingRequests()
//                return
//            }
//
//            guard isInternetAvailable() else {
//                print("No internet connection. Using cached data if available.")
//                processPendingRequests()
//                return
//            }
//
//            print("Starting data request for segment: \(url.absoluteString)") // Log segment download start
//            let configuration = URLSessionConfiguration.default
//            configuration.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
//            session = URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
//            let dataTask = session?.dataTask(with: url)
//            dataTask?.resume()
//        }
//
//        func resourceLoader(_ resourceLoader: AVAssetResourceLoader, didCancel loadingRequest: AVAssetResourceLoadingRequest) {
//            pendingRequestsQueue.sync {
//                pendingRequests.remove(loadingRequest)
//            }
//        }
//
//        func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
//            if mediaData == nil {
//                mediaData = Data()
//            }
//            mediaData?.append(data)
//            print("Downloading segment: \(dataTask.currentRequest?.url?.absoluteString ?? "unknown URL") - Downloaded \(mediaData!.count) bytes") // Log segment download progress
//            processPendingRequests()
//            owner?.delegate?.playerItem?(owner!, didDownloadBytesSoFar: mediaData!.count, outOf: Int(dataTask.countOfBytesExpectedToReceive))
//        }
//
//        func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
//            completionHandler(.allow)
//            mediaData = Data()
//            self.response = response
//            print("Received response for segment: \(dataTask.currentRequest?.url?.absoluteString ?? "unknown URL")") // Log segment response
//            processPendingRequests()
//        }
//
//        func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
//            if let errorUnwrapped = error {
//                print("Error downloading segment: \(task.currentRequest?.url?.absoluteString ?? "unknown URL") - \(errorUnwrapped.localizedDescription)") // Log segment download error
//                owner?.delegate?.playerItem?(owner!, downloadingFailedWith: errorUnwrapped)
//                return
//            }
//
//            if let segmentUrl = task.currentRequest?.url, let data = mediaData {
//                cachedSegments[segmentUrl] = data
//                if let localFileURL = localFileURL(for: segmentUrl) {
//                    do {
//                        try data.write(to: localFileURL)
//                        print("Segment saved to: \(localFileURL.path)")
//                    } catch {
//                        print("Failed to save segment to: \(localFileURL.path) - Error: \(error.localizedDescription)")
//                    }
//                }
//            }
//
//            print("Completed downloading segment: \(task.currentRequest?.url?.absoluteString ?? "unknown URL")") // Log segment download completion
//            owner?.delegate?.playerItem?(owner!, didFinishDownloadingData: mediaData!)
//            processPendingRequests()
//        }
//
//        func processPendingRequests() {
//            pendingRequestsQueue.sync {
//                let requestsFulfilled = Set<AVAssetResourceLoadingRequest>(pendingRequests.compactMap {
//                    fillInContentInformationRequest($0.contentInformationRequest)
//                    if haveEnoughDataToFulfillRequest($0.dataRequest!) {
//                        $0.finishLoading()
//                        return $0
//                    }
//                    return nil
//                })
//                requestsFulfilled.forEach { pendingRequests.remove($0) }
//            }
//        }
//
//        func fillInContentInformationRequest(_ contentInformationRequest: AVAssetResourceLoadingContentInformationRequest?) {
//            if playingFromData {
//                contentInformationRequest?.contentType = self.mimeType
//                contentInformationRequest?.contentLength = Int64(mediaData!.count)
//                contentInformationRequest?.isByteRangeAccessSupported = true
//                return
//            }
//
//            guard let responseUnwrapped = response else { return }
//            contentInformationRequest?.contentType = responseUnwrapped.mimeType
//            contentInformationRequest?.contentLength = responseUnwrapped.expectedContentLength
//            contentInformationRequest?.isByteRangeAccessSupported = true
//        }
//
//        func haveEnoughDataToFulfillRequest(_ dataRequest: AVAssetResourceLoadingDataRequest) -> Bool {
//            let requestedOffset = Int(dataRequest.requestedOffset)
//            let requestedLength = dataRequest.requestedLength
//            let currentOffset = Int(dataRequest.currentOffset)
//
//            guard let songDataUnwrapped = mediaData, songDataUnwrapped.count > currentOffset else {
//                return false
//            }
//
//            let bytesToRespond = min(songDataUnwrapped.count - currentOffset, requestedLength)
//            let dataToRespond = songDataUnwrapped.subdata(in: currentOffset..<(currentOffset + bytesToRespond))
//            dataRequest.respond(with: dataToRespond)
//
//            return songDataUnwrapped.count >= requestedLength + requestedOffset
//        }
//
//        deinit {
//            session?.invalidateAndCancel()
//        }
//
//        // Reachability check
//        private func isInternetAvailable() -> Bool {
//            var zeroAddress = sockaddr_in()
//            zeroAddress.sin_len = UInt8(MemoryLayout<sockaddr_in>.size)
//            zeroAddress.sin_family = sa_family_t(AF_INET)
//
//            let defaultRouteReachability = withUnsafePointer(to: &zeroAddress) {
//                $0.withMemoryRebound(to: sockaddr.self, capacity: 1) { zeroSockAddress in
//                    SCNetworkReachabilityCreateWithAddress(nil, zeroSockAddress)
//                }
//            }
//
//            var flags: SCNetworkReachabilityFlags = []
//            if !SCNetworkReachabilityGetFlags(defaultRouteReachability!, &flags) {
//                return false
//            }
//            let isReachable = flags.contains(.reachable)
//            let needsConnection = flags.contains(.connectionRequired)
//            return (isReachable && !needsConnection)
//        }
//
//        private func localFileURL(for url: URL?) -> URL? {
//            guard let url = url, let cacheDirectory = cacheDirectory() else { return nil }
//            var components = url.pathComponents
//            guard components.count >= 3 else { return nil }
//            let resolutionDirectory = components[components.count - 2] // "720p" for example
//
//            // Append resolution directory to cache directory
//            let resolutionCacheDirectory = cacheDirectory.appendingPathComponent(resolutionDirectory)
//
//            // Create resolution directory if it doesn't exist
//            do {
//                try FileManager.default.createDirectory(at: resolutionCacheDirectory, withIntermediateDirectories: true, attributes: nil)
//            } catch {
//                print("Error creating resolution directory: \(error.localizedDescription)")
//                return nil
//            }
//
//            let fileName = url.lastPathComponent
//            return resolutionCacheDirectory.appendingPathComponent(fileName)
//        }
//
//        // Function to log the file path
//        private func logFilePath(for url: URL?) {
//            guard let fileURL = localFileURL(for: url) else {
//                print("Error generating local file URL.")
//                return
//            }
//
//            let fileManager = FileManager.default
//            if fileManager.fileExists(atPath: fileURL.path) {
//                print("File exists at path: \(fileURL.path)")
//            } else {
//                print("File not found at path: \(fileURL.path)")
//            }
//        }
//
//        // Function to get the cache directory
//        private func cacheDirectory() -> URL? {
//            return FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
//        }
//    }
//
//    let resourceLoaderDelegate = ResourceLoaderDelegate()
//    public let url: URL
//    fileprivate let initialScheme: String?
//    fileprivate var customFileExtension: String?
//
//    public weak var delegate: CachingPlayerItemDelegate?
//    public weak var stateDelegate: CachingPlayerItemStateDelegate?
//
//    open func download() {
//        if resourceLoaderDelegate.session == nil {
//            resourceLoaderDelegate.startDataRequest(with: url)
//        }
//    }
//
//    private let cachingPlayerItemScheme = "https"
//
//    convenience init(url: URL) {
//        self.init(url: url, customFileExtension: nil)
//    }
//    
//    func segmentURL(for time: CMTime) -> URL? {
//        // Assuming segment duration is uniform and calculated based on the playlist or a fixed value
//        let segmentDuration: Double = 10.0 // Duration of each segment in seconds
//        let segmentIndex = Int(CMTimeGetSeconds(time) / segmentDuration)
//        guard segmentIndex >= 0 && segmentIndex < resourceLoaderDelegate.segmentUrls.count else {
//            return nil
//        }
//        return resourceLoaderDelegate.segmentUrls[segmentIndex]
//    }
//
//    func handleSeek(to time: CMTime) {
//        guard let segmentUrl = segmentURL(for: time) else {
//            print("Segment URL not found for the given time.")
//            return
//        }
//        
//        // Clear current data and pending requests
//        resourceLoaderDelegate.mediaData = nil
//        resourceLoaderDelegate.pendingRequestsQueue.sync {
//            resourceLoaderDelegate.pendingRequests.removeAll()
//        }
//        
//        // Start downloading the segment corresponding to the seek position
//        resourceLoaderDelegate.startDataRequest(with: segmentUrl)
//        
//        // Also update the segment URL list to prioritize future segments starting from the seek position
//        if let segmentIndex = resourceLoaderDelegate.segmentUrls.firstIndex(of: segmentUrl) {
//            resourceLoaderDelegate.segmentUrls = Array(resourceLoaderDelegate.segmentUrls[segmentIndex...])
//        }
//    }
//
//
//    public init(url: URL, customFileExtension: String?) {
//        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
//              let scheme = components.scheme,
//              var urlWithCustomScheme = url.withScheme(cachingPlayerItemScheme) else {
//            fatalError("Urls without a scheme are not supported")
//        }
//
//        self.url = url
//        self.initialScheme = scheme
//
//        if let ext = customFileExtension {
//            urlWithCustomScheme.deletePathExtension()
//            urlWithCustomScheme.appendPathExtension(ext)
//        }
//
//        let asset = AVURLAsset(url: urlWithCustomScheme)
//        asset.resourceLoader.setDelegate(resourceLoaderDelegate, queue: .main)
//
//        self.customFileExtension = customFileExtension
//        super.init(asset: asset, automaticallyLoadedAssetKeys: nil)
//
//        resourceLoaderDelegate.owner = self
//
//        addObserver(self, forKeyPath: "status", options: .new, context: nil)
//        addObserver(self, forKeyPath: "playbackBufferEmpty", options: .new, context: nil)
//        addObserver(self, forKeyPath: "playbackLikelyToKeepUp", options: .new, context: nil)
//    }
//
//    override open func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
//        if keyPath == "playbackBufferEmpty" {
//            stateDelegate?.playerItemStateChange(self, changedTo: .playbackBufferEmpty)
//            delegate?.playerItemPlaybackStalled?(self)
//        } else if keyPath == "playbackLikelyToKeepUp" {
//            stateDelegate?.playerItemStateChange(self, changedTo: .playbackLikelyToKeepUp)
//        } else if keyPath == "status" {
//            stateDelegate?.playerItemStateChange(self, changedTo: .statusChanged)
//        }
//    }
//
//    deinit {
//            self.asset.cancelLoading()
//            NotificationCenter.default.removeObserver(self)
//            resourceLoaderDelegate.session?.invalidateAndCancel()
//        }
//    
//    @objc func playbackStalled(_ notification: Notification) {
//            delegate?.playerItemPlaybackStalled?(self)
//        }
//
//        @objc func didPlayToEndTime(_ notification: Notification) {
//            delegate?.playerItemReadyToPlay?(self)
//        }
//
//    func parseM3U8Playlist(from data: Data, baseUrl: URL) -> [URL]? {
//        guard let playlistString = String(data: data, encoding: .utf8) else { return nil }
//        let lines = playlistString.components(separatedBy: .newlines)
//        var segmentURLs = [URL]()
//
//        for line in lines {
//            if line.hasSuffix(".m4s") { // Typically HLS segments end with .ts
//                if let url = URL(string: line, relativeTo: baseUrl) {
//                    segmentURLs.append(url)
//                }
//            }
//        }
//        return segmentURLs
//    }
//
//    func fetchAllSegments(from playlistURL: URL) {
//        let task = URLSession.shared.dataTask(with: playlistURL) { data, response, error in
//            guard let data = data, error == nil else {
//                print("Failed to download playlist: \(error?.localizedDescription ?? "No error description")")
//                return
//            }
//
//            if let segmentURLs = self.parseM3U8Playlist(from: data, baseUrl: playlistURL) {
//                self.resourceLoaderDelegate.segmentUrls = segmentURLs
//                if let firstSegment = segmentURLs.first {
//                    self.resourceLoaderDelegate.startDataRequest(with: firstSegment)
//                }
//            }
//        }
//        task.resume()
//    }
//}



import Foundation
import AVFoundation
import SystemConfiguration

fileprivate extension URL {
    func withScheme(_ scheme: String) -> URL? {
        var components = URLComponents(url: self, resolvingAgainstBaseURL: false)
        components?.scheme = scheme
        return components?.url
    }
}

public enum CachingPlayerItemState {
    case playbackBufferEmpty
    case playbackLikelyToKeepUp
    case none
    case statusChanged
}

public protocol CachingPlayerItemStateDelegate: AnyObject {
    func playerItemStateChange(_ playerItem: CachingPlayerItem, changedTo state: CachingPlayerItemState)
}

@objc public protocol CachingPlayerItemDelegate {
    @objc optional func playerItem(_ playerItem: CachingPlayerItem, didFinishDownloadingData data: Data)
    @objc optional func playerItem(_ playerItem: CachingPlayerItem, didDownloadBytesSoFar bytesDownloaded: Int, outOf bytesExpected: Int)
    @objc optional func playerItemReadyToPlay(_ playerItem: CachingPlayerItem)
    @objc optional func playerItemPlaybackStalled(_ playerItem: CachingPlayerItem)
    @objc optional func playerItem(_ playerItem: CachingPlayerItem, downloadingFailedWith error: Error)
}

open class CachingPlayerItem: AVPlayerItem {
    class ResourceLoaderDelegate: NSObject, AVAssetResourceLoaderDelegate, URLSessionDelegate, URLSessionDataDelegate, URLSessionTaskDelegate {
        var playingFromData = false
        var mimeType: String?
        var session: URLSession?
        public var mediaData: Data?
        var response: URLResponse?
        var pendingRequests = Set<AVAssetResourceLoadingRequest>()
        let pendingRequestsQueue = DispatchQueue(label: "CachingPlayerItem.pendingRequestsQueue")
        weak var owner: CachingPlayerItem?

        private var cachedSegments: [URL: Data] = [:] // Cache for segments
        private var currentSegmentUrl: URL?
        var segmentUrls: [URL] = [] // URLs of all segments
        var currentSegmentIndex = 0 // Track the index of the current segment

        func resourceLoader(_ resourceLoader: AVAssetResourceLoader, shouldWaitForLoadingOfRequestedResource loadingRequest: AVAssetResourceLoadingRequest) -> Bool {
            if playingFromData {
                return false
            } else if session == nil {
                guard let initialUrl = owner?.url else { return false }
                startDataRequest(with: initialUrl)
            }

            pendingRequestsQueue.sync {
                pendingRequests.insert(loadingRequest)
            }
            processPendingRequests()
            return true
        }

        func startDataRequest(with url: URL) {
            if let cachedData = cachedSegments[url] {
                mediaData = cachedData
                processPendingRequests()
                return
            }

//            guard isInternetAvailable() else {
//                print("No internet connection. Using cached data if available.")
//                processPendingRequests()
//                return
//            }

            print("Starting data request for segment: \(url.absoluteString)") // Log segment download start
            let configuration = URLSessionConfiguration.default
            configuration.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
            session = URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
            let dataTask = session?.dataTask(with: url)
            dataTask?.resume()
        }

        func resourceLoader(_ resourceLoader: AVAssetResourceLoader, didCancel loadingRequest: AVAssetResourceLoadingRequest) {
            pendingRequestsQueue.sync {
                pendingRequests.remove(loadingRequest)
            }
        }

        func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
            if mediaData == nil {
                mediaData = Data()
            }
            mediaData?.append(data)
            print("Downloading segment: \(dataTask.currentRequest?.url?.absoluteString ?? "unknown URL") - Downloaded \(mediaData!.count) bytes") // Log segment download progress
            processPendingRequests()
            owner?.delegate?.playerItem?(owner!, didDownloadBytesSoFar: mediaData!.count, outOf: Int(dataTask.countOfBytesExpectedToReceive))
        }

        func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
            completionHandler(.allow)
            mediaData = Data()
            self.response = response
            print("Received response for segment: \(dataTask.currentRequest?.url?.absoluteString ?? "unknown URL")") // Log segment response
            processPendingRequests()
        }

        func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
            if let errorUnwrapped = error {
                print("Error downloading segment: \(task.currentRequest?.url?.absoluteString ?? "unknown URL") - \(errorUnwrapped.localizedDescription)") // Log segment download error
                owner?.delegate?.playerItem?(owner!, downloadingFailedWith: errorUnwrapped)
                return
            }

            if let segmentUrl = task.currentRequest?.url, let data = mediaData {
                cachedSegments[segmentUrl] = data
                if let localFileURL = localFileURL(for: segmentUrl) {
                    do {
                        try data.write(to: localFileURL)
                        print("Segment saved to: \(localFileURL.path)")
                    } catch {
                        print("Failed to save segment to: \(localFileURL.path) - Error: \(error.localizedDescription)")
                    }
                }
            }

            print("Completed downloading segment: \(task.currentRequest?.url?.absoluteString ?? "unknown URL")") // Log segment download completion
            owner?.delegate?.playerItem?(owner!, didFinishDownloadingData: mediaData!)

            // Fetch the next segment
            fetchNextSegment()

            processPendingRequests()
        }

        func fetchNextSegment() {
            currentSegmentIndex += 1
            guard currentSegmentIndex < segmentUrls.count else {
                print("All segments have been fetched.")
                return
            }
            startDataRequest(with: segmentUrls[currentSegmentIndex])
        }

        func processPendingRequests() {
            pendingRequestsQueue.sync {
                let requestsFulfilled = Set<AVAssetResourceLoadingRequest>(pendingRequests.compactMap {
                    fillInContentInformationRequest($0.contentInformationRequest)
                    if haveEnoughDataToFulfillRequest($0.dataRequest!) {
                        $0.finishLoading()
                        return $0
                    }
                    return nil
                })
                requestsFulfilled.forEach { pendingRequests.remove($0) }
            }
        }

        func fillInContentInformationRequest(_ contentInformationRequest: AVAssetResourceLoadingContentInformationRequest?) {
            if playingFromData {
                contentInformationRequest?.contentType = self.mimeType
                contentInformationRequest?.contentLength = Int64(mediaData!.count)
                contentInformationRequest?.isByteRangeAccessSupported = true
                return
            }

            guard let responseUnwrapped = response else { return }
            contentInformationRequest?.contentType = responseUnwrapped.mimeType
            contentInformationRequest?.contentLength = responseUnwrapped.expectedContentLength
            contentInformationRequest?.isByteRangeAccessSupported = true
        }

        func haveEnoughDataToFulfillRequest(_ dataRequest: AVAssetResourceLoadingDataRequest) -> Bool {
            let requestedOffset = Int(dataRequest.requestedOffset)
            let requestedLength = dataRequest.requestedLength
            let currentOffset = Int(dataRequest.currentOffset)

            guard let songDataUnwrapped = mediaData, songDataUnwrapped.count > currentOffset else {
                return false
            }

            let bytesToRespond = min(songDataUnwrapped.count - currentOffset, requestedLength)
            let dataToRespond = songDataUnwrapped.subdata(in: currentOffset..<(currentOffset + bytesToRespond))
            dataRequest.respond(with: dataToRespond)

            return songDataUnwrapped.count >= requestedLength + requestedOffset
        }

        deinit {
            session?.invalidateAndCancel()
        }

        // Reachability check
//        private func isInternetAvailable() -> Bool {
//            var zeroAddress = sockaddr_in()
//            zeroAddress.sin_len = UInt8(MemoryLayout<sockaddr_in>.size)
//            zeroAddress.sin_family = sa_family_t(AF_INET)
//
//            let defaultRouteReachability = withUnsafePointer(to: &zeroAddress) {
//                $0.withMemoryRebound(to: sockaddr.self, capacity: 1) { zeroSockAddress in
//                    SCNetworkReachabilityCreateWithAddress(nil, zeroSockAddress)
//                }
//            }
//
//            var flags: SCNetworkReachabilityFlags = []
//            if !SCNetworkReachabilityGetFlags(defaultRouteReachability!, &flags) {
//                return false
//            }
//            let isReachable = flags.contains(.reachable)
//            let needsConnection = flags.contains(.connectionRequired)
//            return (isReachable && !needsConnection)
//        }

        private func localFileURL(for url: URL?) -> URL? {
            guard let url = url, let cacheDirectory = cacheDirectory() else { return nil }
            var components = url.pathComponents
            guard components.count >= 3 else { return nil }
            let resolutionDirectory = components[components.count - 2] // "720p" for example
            //work on this

            // Append resolution directory to cache directory
            let resolutionCacheDirectory = cacheDirectory.appendingPathComponent(resolutionDirectory)

            // Create resolution directory if it doesn't exist
            do {
                try FileManager.default.createDirectory(at: resolutionCacheDirectory, withIntermediateDirectories: true, attributes: nil)
            } catch {
                print("Error creating resolution directory: \(error.localizedDescription)")
                return nil
            }

            let fileName = url.lastPathComponent
            return resolutionCacheDirectory.appendingPathComponent(fileName)
        }

//        // Function to log the file path
//        private func logFilePath(for url: URL?) {
//            guard let fileURL = localFileURL(for: url) else {
//                print("Error generating local file URL.")
//                return
//            }
//
//            let fileManager = FileManager.default
//            if fileManager.fileExists(atPath: fileURL.path) {
//                print("File exists at path: \(fileURL.path)")
//            } else {
//                print("File not found at path: \(fileURL.path)")
//            }
//        }

        // Function to get the cache directory
        private func cacheDirectory() -> URL? {
            return FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
        }
    }

    let resourceLoaderDelegate = ResourceLoaderDelegate()
    public let url: URL
    fileprivate let initialScheme: String?
    fileprivate var customFileExtension: String?

    public weak var delegate: CachingPlayerItemDelegate?
    public weak var stateDelegate: CachingPlayerItemStateDelegate?

    open func download() {
        if resourceLoaderDelegate.session == nil {
            resourceLoaderDelegate.startDataRequest(with: url)
        }
    }

    private let cachingPlayerItemScheme = "https"

    convenience init(url: URL) {
        self.init(url: url, customFileExtension: nil)
    }
    
    func segmentURL(for time: CMTime) -> URL? {
        // Assuming segment duration is uniform and calculated based on the playlist or a fixed value
        let segmentDuration: Double = 10.0 // Duration of each segment in seconds
        let segmentIndex = Int(CMTimeGetSeconds(time) / segmentDuration)
        guard segmentIndex >= 0 && segmentIndex < resourceLoaderDelegate.segmentUrls.count else {
            return nil
        }
        return resourceLoaderDelegate.segmentUrls[segmentIndex]
    }

    func handleSeek(to time: CMTime) {
        guard let segmentUrl = segmentURL(for: time) else {
            print("Segment URL not found for the given time.")
            return
        }
        
        // Clear current data and pending requests
        resourceLoaderDelegate.mediaData = nil
        resourceLoaderDelegate.pendingRequestsQueue.sync {
            resourceLoaderDelegate.pendingRequests.removeAll()
        }
        
        // Start downloading the segment corresponding to the seek position
        resourceLoaderDelegate.startDataRequest(with: segmentUrl)
        
        // Also update the segment URL list to prioritize future segments starting from the seek position
        if let segmentIndex = resourceLoaderDelegate.segmentUrls.firstIndex(of: segmentUrl) {
            resourceLoaderDelegate.segmentUrls = Array(resourceLoaderDelegate.segmentUrls[segmentIndex...])
            resourceLoaderDelegate.currentSegmentIndex = segmentIndex
        }
    }


    public init(url: URL, customFileExtension: String?) {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let scheme = components.scheme,
              var urlWithCustomScheme = url.withScheme(cachingPlayerItemScheme) else {
            fatalError("Urls without a scheme are not supported")
        }

        self.url = url
        self.initialScheme = scheme

        if let ext = customFileExtension {
            urlWithCustomScheme.deletePathExtension()
            urlWithCustomScheme.appendPathExtension(ext)
        }

        let asset = AVURLAsset(url: urlWithCustomScheme)
        asset.resourceLoader.setDelegate(resourceLoaderDelegate, queue: .main)

        self.customFileExtension = customFileExtension
        super.init(asset: asset, automaticallyLoadedAssetKeys: nil)

        resourceLoaderDelegate.owner = self

        addObserver(self, forKeyPath: "status", options: .new, context: nil)
        addObserver(self, forKeyPath: "playbackBufferEmpty", options: .new, context: nil)
        addObserver(self, forKeyPath: "playbackLikelyToKeepUp", options: .new, context: nil)
    }

    override open func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "playbackBufferEmpty" {
            stateDelegate?.playerItemStateChange(self, changedTo: .playbackBufferEmpty)
            delegate?.playerItemPlaybackStalled?(self)
        } else if keyPath == "playbackLikelyToKeepUp" {
            stateDelegate?.playerItemStateChange(self, changedTo: .playbackLikelyToKeepUp)
        } else if keyPath == "status" {
            stateDelegate?.playerItemStateChange(self, changedTo: .statusChanged)
        }
    }

    deinit {
            self.asset.cancelLoading()
            NotificationCenter.default.removeObserver(self)
            resourceLoaderDelegate.session?.invalidateAndCancel()
        }
    
    @objc func playbackStalled(_ notification: Notification) {
            delegate?.playerItemPlaybackStalled?(self)
        }

    @objc func didPlayToEndTime(_ notification: Notification) {
        delegate?.playerItemReadyToPlay?(self)
    }

    func parseM3U8Playlist(from data: Data, baseUrl: URL) -> [URL]? {
        guard let playlistString = String(data: data, encoding: .utf8) else { return nil }
        let lines = playlistString.components(separatedBy: .newlines)
        var segmentURLs = [URL]()

        for line in lines {
            if line.hasSuffix(".m4s") {
                if let url = URL(string: line, relativeTo: baseUrl) {
                    segmentURLs.append(url)
                }
            }
        }
        return segmentURLs
    }

    func fetchAllSegments(from playlistURL: URL) {
        let task = URLSession.shared.dataTask(with: playlistURL) { data, response, error in
            guard let data = data, error == nil else {
                print("Failed to download playlist: \(error?.localizedDescription ?? "No error description")")
                return
            }

            if let segmentURLs = self.parseM3U8Playlist(from: data, baseUrl: playlistURL) {
                self.resourceLoaderDelegate.segmentUrls = segmentURLs
                if let firstSegment = segmentURLs.first {
                    self.resourceLoaderDelegate.startDataRequest(with: firstSegment)
                }
            }
        }
        task.resume()
    }
}


