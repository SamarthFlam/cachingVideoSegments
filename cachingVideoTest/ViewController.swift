//MARK: working code

//import UIKit
//import AVKit
//
//class ViewController: UIViewController, CachingPlayerItemDelegate, CachingPlayerItemStateDelegate {
//
//    var playerViewController: AVPlayerViewController!
//    var player: AVPlayer!
//    var cacheManager = CacheManager.shared
//    
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        
//        // Initialize AVPlayerViewController
//        playerViewController = AVPlayerViewController()
//        playerViewController.view.frame = view.bounds
//        addChild(playerViewController)
//        view.addSubview(playerViewController.view)
//        
//        // HLS URL (default)
//        let baseURLString = "https://storage.googleapis.com/zingcam/flam/prod/streaming/Combo/hls/"
////        let baseURLString = "https://zingcam.cdn.flamapp.com/flam/prod/streaming/samsung_prod/hls/"
//        let initialURLString = "master_combo.m3u8" // Default to master playlist
//        
//        guard let initialURL = URL(string: baseURLString + initialURLString) else {
//            fatalError("Invalid initial URL")
//        }
//        
//        // Initialize AVPlayer with initial URL
////        let cachingPlayerItem = CachingPlayerItem(url: initialURL, resolution: "master")
//        let cachingPlayerItem = CachingPlayerItem(url: initialURL)
//        cachingPlayerItem.delegate = self
//        cachingPlayerItem.stateDelegate = self
//        
//        player = AVPlayer(playerItem: cachingPlayerItem)
//        playerViewController.player = player
//        
//        // Start playing automatically
//        player.play()
//        
//        // Add resolution change buttons
//        addResolutionButtons()
//        
//        // Initialize reachability
//        cacheManager.startReachability()
//    }
//    
//    func addResolutionButtons() {
//        let buttonTitles = ["Auto", "1080p", "720p", "480p", "360p"]
//        let buttonWidth = view.frame.width / CGFloat(buttonTitles.count)
//        
//        for (index, title) in buttonTitles.enumerated() {
//            let button = UIButton(frame: CGRect(x: buttonWidth * CGFloat(index), y: view.frame.height - 120, width: buttonWidth, height: 50))
//            button.backgroundColor = .darkGray
//            button.setTitle(title, for: .normal)
//            button.tag = index
//            button.addTarget(self, action: #selector(changeResolution(_:)), for: .touchUpInside)
//            view.addSubview(button)
//        }
//    }
//    
//    @objc func changeResolution(_ sender: UIButton) {
//        let baseURLString = "https://storage.googleapis.com/zingcam/flam/prod/streaming/Combo/hls/"
////        let baseURLString = "https://zingcam.cdn.flamapp.com/flam/prod/streaming/samsung_prod/hls/"
//        
//        var resolution: String
//        var resolutionURLString: String
//        
//        switch sender.tag {
//        case 0: // Auto (use the original master playlist)
//            resolution = "master"
//            resolutionURLString = "master_combo.m3u8"
//        case 1: // 1080p
//            resolution = "1080p"
//            resolutionURLString = "1080p/stream.m3u8"
//        case 2: // 720p
//            resolution = "720p"
//            resolutionURLString = "720p/stream.m3u8"
//        case 3: // 480p
//            resolution = "480p"
//            resolutionURLString = "480p/stream.m3u8"
//        case 4: // 360p
//            resolution = "360p"
//            resolutionURLString = "360p/stream.m3u8"
//        default:
//            return
//        }
//        
//        guard let url = URL(string: baseURLString + resolutionURLString) else { return }
//        
//        // Check if the item is cached
//        if let cachingPlayerItem = cacheManager.cacheItems[resolutionURLString] {
//            // Use cached item
//            player.replaceCurrentItem(with: cachingPlayerItem)
//            
//            print("Playing from cache for resolution: \(sender.titleLabel?.text ?? "Unknown")")
//            
//            // Start playing automatically
//            player.play()
//        } else {
//            // Create new caching player item
////            let cachingPlayerItem = CachingPlayerItem(url: url, resolution: resolution)
//            let cachingPlayerItem = CachingPlayerItem(url: url)
//            cachingPlayerItem.fetchAllSegments(from: url)
//            cachingPlayerItem.delegate = self
//            cachingPlayerItem.stateDelegate = self
//            
//            // Cache the item
//            cacheManager.cacheItems[resolutionURLString] = cachingPlayerItem
//            cachingPlayerItem.download()
//            
//            // Replace current AVPlayerItem with the new caching player item
//            player.replaceCurrentItem(with: cachingPlayerItem)
//            
//            // Start playing automatically
//            player.play()
//        }
//    }
//    
//    // CachingPlayerItemDelegate methods
//    func playerItem(_ playerItem: CachingPlayerItem, didFinishDownloadingData data: Data) {
//        print("File is downloaded and ready for storing")
//        CacheManager.shared.storage?.async.setObject(data, forKey: playerItem.url.absoluteString, completion: { _ in })
//        print("data: \(data)")
//        print("player: \(playerItem.url.absoluteString)")
//    }
//    
//    func playerItem(_ playerItem: CachingPlayerItem, didDownloadBytesSoFar bytesDownloaded: Int, outOf bytesExpected: Int) {
//        print("\(bytesDownloaded)/\(bytesExpected)")
//    }
//    
//    func playerItemPlaybackStalled(_ playerItem: CachingPlayerItem) {
//        print("Playback stalled, buffering...")
//    }
//    
//    func playerItem(_ playerItem: CachingPlayerItem, downloadingFailedWith error: Error) {
//        print("Downloading failed: \(error.localizedDescription)")
//        let newItem = AVPlayerItem(url: playerItem.url)
//        player.replaceCurrentItem(with: newItem)
//        player.play()
//    }
//    
//    // CachingPlayerItemStateDelegate methods
//    func playerItemStateChange(_ playerItem: CachingPlayerItem, changedTo state: CachingPlayerItemState) {
//        switch state {
//        case .playbackBufferEmpty:
//            print("Buffering...")
//        case .playbackLikelyToKeepUp:
//            print("Playback likely to keep up")
//        case .statusChanged:
//            if playerItem.status == .readyToPlay {
//                print("Ready to play")
//                player.play()
//            }
//        case .none:
//            break
//        }
//    }
//}

//most working code





//import UIKit
//import AVKit
//
//class ViewController: UIViewController, CachingPlayerItemDelegate, CachingPlayerItemStateDelegate {
//    
//    var playerViewController: AVPlayerViewController!
//    var player: AVPlayer!
//    var cacheManager = CacheManager.shared
//    
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        
//        // Initialize AVPlayerViewController
//        playerViewController = AVPlayerViewController()
//        playerViewController.view.frame = view.bounds
//        addChild(playerViewController)
//        view.addSubview(playerViewController.view)
//        
//        // HLS URL (default)
//        let baseURLString = "https://storage.googleapis.com/zingcam/flam/prod/streaming/Combo/hls/"
//        let initialURLString = "master_combo.m3u8" // Default to master playlist
//        
//        guard let initialURL = URL(string: baseURLString + initialURLString) else {
//            fatalError("Invalid initial URL")
//        }
//        
//        player = AVPlayer(url: initialURL)
//        playerViewController.player = player
//        
//        // Start playing automatically
//        playerViewController.player?.play()
//        
//        // Add resolution change buttons
//        addResolutionButtons()
//        
//        // Initialize reachability
//        cacheManager.startReachability()
//    }
//    
//    func addResolutionButtons() {
//        let buttonTitles = ["Auto", "1080p", "720p", "480p", "360p"]
//        let buttonWidth = view.frame.width / CGFloat(buttonTitles.count)
//        
//        for (index, title) in buttonTitles.enumerated() {
//            let button = UIButton(frame: CGRect(x: buttonWidth * CGFloat(index), y: view.frame.height - 100, width: buttonWidth, height: 50))
//            button.backgroundColor = .darkGray
//            button.setTitle(title, for: .normal)
//            button.tag = index
//            button.addTarget(self, action: #selector(changeResolution(_:)), for: .touchUpInside)
//            view.addSubview(button)
//        }
//    }
//    
//    @objc func changeResolution(_ sender: UIButton) {
//        let baseURLString = "https://storage.googleapis.com/zingcam/flam/prod/streaming/Combo/hls/"
//        
//        var resolutionURLString: String
//        
//        switch sender.tag {
//        case 0: // Auto (use the original master playlist)
//            resolutionURLString = "master_combo.m3u8"
//        case 1: // 1080p
//            resolutionURLString = "1080p/stream.m3u8"
//        case 2: // 720p
//            resolutionURLString = "720p/stream.m3u8"
//        case 3: // 480p
//            resolutionURLString = "480p/stream.m3u8"
//        case 4: // 360p
//            resolutionURLString = "360p/stream.m3u8"
//        default:
//            return
//        }
//        
//        guard let url = URL(string: baseURLString + resolutionURLString) else { return }
//        
//        if cacheManager.hasInternet {
//            // Internet is available
//            if let cachedData = cacheManager.localData(for: resolutionURLString) {
//                // Use cached data from local storage
//                let cachingPlayerItem = CachingPlayerItem(data: cachedData, mimeType: "application/x-mpegURL", fileExtension: "m3u8")
//                cachingPlayerItem.delegate = self
//                cachingPlayerItem.stateDelegate = self
//                player.replaceCurrentItem(with: cachingPlayerItem)
//                
//                print("Playing from cache for resolution: \(sender.titleLabel?.text ?? "Unknown")")
//                player.play()
//            } else {
//                // No cached data in local storage, download and cache the item
//                let cachingPlayerItem = CachingPlayerItem(url: url)
//                cachingPlayerItem.delegate = self
//                cachingPlayerItem.stateDelegate = self
//                
//                cacheManager.cacheItems[resolutionURLString] = cachingPlayerItem
//                cachingPlayerItem.download()
//                
//                player.replaceCurrentItem(with: cachingPlayerItem)
//                player.play()
//            }
//        } else {
//            // No internet, try to play from local storage if available
//            if let cachedData = cacheManager.localData(for: resolutionURLString) {
//                // Use cached data from local storage
//                let cachingPlayerItem = CachingPlayerItem(data: cachedData, mimeType: "application/x-mpegURL", fileExtension: "m3u8")
//                cachingPlayerItem.delegate = self
//                cachingPlayerItem.stateDelegate = self
//                player.replaceCurrentItem(with: cachingPlayerItem)
//                
//                print("Playing from local storage for resolution: \(sender.titleLabel?.text ?? "Unknown")")
//                player.play()
//            } else {
//                // No local data available, handle this case as needed
//                print("No internet and no local data available for resolution: \(sender.titleLabel?.text ?? "Unknown")")
//            }
//        }
//    }
//
//    
//    // CachingPlayerItemDelegate methods
//    func playerItem(_ playerItem: CachingPlayerItem, didFinishDownloadingData data: Data) {
//        print("File is downloaded and ready for storing")
//        
//        // Save the data to cache
//        cacheManager.save(data: data, for: playerItem.url.absoluteString)
//        
//        // Save the data to local storage
//        cacheManager.saveToLocalStorage(data: data, for: playerItem.url.absoluteString)
//    }
//    
//    func playerItem(_ playerItem: CachingPlayerItem, didDownloadBytesSoFar bytesDownloaded: Int, outOf bytesExpected: Int) {
//        print("\(bytesDownloaded)/\(bytesExpected)")
//    }
//    
//    func playerItemPlaybackStalled(_ playerItem: CachingPlayerItem) {
//        print("Not enough data for playback. Probably because of the poor network. Wait a bit and try to play later.")
//    }
//    
//    func playerItem(_ playerItem: CachingPlayerItem, downloadingFailedWith error: Error) {
//        print("Downloading failed: \(error.localizedDescription)")
//        
//        // Handle the failure here, possibly fallback to direct network playback
//        let url = playerItem.url // playerItem.url is not an optional, so no need for `if let`
//        
//        let newItem = AVPlayerItem(url: url)
//        player.replaceCurrentItem(with: newItem)
//        player.play()
//    }
//    
//    // CachingPlayerItemStateDelegate methods
//    func playerItemStateChange(_ playerItem: CachingPlayerItem, changedTo state: CachingPlayerItemState) {
//        switch state {
//        case .playbackBufferEmpty:
//            print("Buffering")
//        case .playbackLikelyToKeepUp:
//            print("Playback likely to keep up")
//        case .statusChanged:
//            if playerItem.status == .readyToPlay {
//                print("Ready to play")
//                player.play() // Ensure to start playback when ready
//            }
//        case .none:
//            break
//        }
//    }
//    
//    // Other functions (fetchAndParsePlaylist, parseResolution, etc.) remain unchanged
//}



//
//
//import UIKit
//import AVKit
//
//class ViewController: UIViewController, CachingPlayerItemDelegate, CachingPlayerItemStateDelegate {
//
//    var playerViewController: AVPlayerViewController!
//    var player: AVPlayer!
//    var cacheManager = CacheManager.shared
//
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        
//        // Initialize AVPlayerViewController
//        playerViewController = AVPlayerViewController()
//        playerViewController.view.frame = view.bounds
//        addChild(playerViewController)
//        view.addSubview(playerViewController.view)
//        
//        // HLS URL (default)
//        let baseURLString = "https://storage.googleapis.com/zingcam/flam/prod/streaming/Combo/hls/"
////        let baseURLString = "https://zingcam.cdn.flamapp.com/flam/prod/streaming/samsung_prod/hls/"
//        let initialURLString = "master_combo.m3u8" // Default to master playlist
//        
//        guard let initialURL = URL(string: baseURLString + initialURLString) else {
//            fatalError("Invalid initial URL")
//        }
//        
//        // Initialize AVPlayer with initial URL
//        let cachingPlayerItem = CachingPlayerItem(url: initialURL)
//        cachingPlayerItem.delegate = self
//        cachingPlayerItem.stateDelegate = self
//        
//        player = AVPlayer(playerItem: cachingPlayerItem)
//        playerViewController.player = player
//        
//        // Start playing automatically
//        player.play()
//        
//        // Add resolution change buttons
//        addResolutionButtons()
//        
//        // Initialize reachability
//        cacheManager.startReachability()
//        
//        // Add observer for player's status
//        player.addObserver(self, forKeyPath: "status", options: [.new, .old], context: nil)
//        player.addObserver(self, forKeyPath: "timeControlStatus", options: [.new, .old], context: nil)
//    }
//    
//    func addResolutionButtons() {
//        let buttonTitles = ["Auto", "1080p", "720p", "480p", "360p"]
//        let buttonWidth = view.frame.width / CGFloat(buttonTitles.count)
//        
//        for (index, title) in buttonTitles.enumerated() {
//            let button = UIButton(frame: CGRect(x: buttonWidth * CGFloat(index), y: view.frame.height - 100, width: buttonWidth, height: 50))
//            button.backgroundColor = .darkGray
//            button.setTitle(title, for: .normal)
//            button.tag = index
//            button.addTarget(self, action: #selector(changeResolution(_:)), for: .touchUpInside)
//            view.addSubview(button)
//        }
//    }
//    
//    @objc func changeResolution(_ sender: UIButton) {
//        let baseURLString = "https://storage.googleapis.com/zingcam/flam/prod/streaming/Combo/hls/"
////        let baseURLString = "https://zingcam.cdn.flamapp.com/flam/prod/streaming/samsung_prod/hls/"
//        
//        var resolution: String
//        var resolutionURLString: String
//        
//        switch sender.tag {
//        case 0: // Auto (use the original master playlist)
//            resolution = "master"
//            resolutionURLString = "master_combo.m3u8"
//        case 1: // 1080p
//            resolution = "1080p"
//            resolutionURLString = "1080p/stream.m3u8"
//        case 2: // 720p
//            resolution = "720p"
//            resolutionURLString = "720p/stream.m3u8"
//        case 3: // 480p
//            resolution = "480p"
//            resolutionURLString = "480p/stream.m3u8"
//        case 4: // 360p
//            resolution = "360p"
//            resolutionURLString = "360p/stream.m3u8"
//        default:
//            return
//        }
//        
//        guard let url = URL(string: baseURLString + resolutionURLString) else { return }
//        
//        // Check if the item is cached
//        if let cachingPlayerItem = cacheManager.cacheItems[resolutionURLString] {
//            // Use cached item
//            player.replaceCurrentItem(with: cachingPlayerItem)
//            
//            print("Playing from cache for resolution: \(sender.titleLabel?.text ?? "Unknown")")
//            
//            // Start playing automatically
//            player.play()
//        } else {
//            // Create new caching player item
//            let cachingPlayerItem = CachingPlayerItem(url: url)
//            cachingPlayerItem.fetchAllSegments(from: url)
//            cachingPlayerItem.delegate = self
//            cachingPlayerItem.stateDelegate = self
//            
//            // Cache the item
//            cacheManager.cacheItems[resolutionURLString] = cachingPlayerItem
//            cachingPlayerItem.download()
//            
//            // Replace current AVPlayerItem with the new caching player item
//            player.replaceCurrentItem(with: cachingPlayerItem)
//            
//            // Start playing automatically
//            player.play()
//        }
//    }
//    
//    // CachingPlayerItemDelegate methods
//    func playerItem(_ playerItem: CachingPlayerItem, didFinishDownloadingData data: Data) {
//        print("File is downloaded and ready for storing")
//        CacheManager.shared.storage?.async.setObject(data, forKey: playerItem.url.absoluteString, completion: { _ in })
//        print("data: \(data)")
//        print("player: \(playerItem.url.absoluteString)")
//    }
//    
//    func playerItem(_ playerItem: CachingPlayerItem, didDownloadBytesSoFar bytesDownloaded: Int, outOf bytesExpected: Int) {
//        print("\(bytesDownloaded)/\(bytesExpected)")
//    }
//    
//    func playerItemPlaybackStalled(_ playerItem: CachingPlayerItem) {
//        print("Playback stalled, buffering...")
//        
//        // Check if the stalled segment is available in cache
//        do {
//            if let cachedData = try CacheManager.shared.storage?.object(forKey: playerItem.url.absoluteString) {
//                print("Using cached data")
//                let asset = AVURLAsset(url: playerItem.url)
//                let newItem = AVPlayerItem(asset: asset)
//                player.replaceCurrentItem(with: newItem)
//                player.play()
//            }
//        } catch {
//            print("Error retrieving cached data: \(error.localizedDescription)")
//        }
//    }
//    
//    func playerItem(_ playerItem: CachingPlayerItem, downloadingFailedWith error: Error) {
//        print("Downloading failed: \(error.localizedDescription)")
//        let newItem = AVPlayerItem(url: playerItem.url)
//        player.replaceCurrentItem(with: newItem)
//        player.play()
//    }
//    
//    // CachingPlayerItemStateDelegate methods
//    func playerItemStateChange(_ playerItem: CachingPlayerItem, changedTo state: CachingPlayerItemState) {
//        switch state {
//        case .playbackBufferEmpty:
//            print("Buffering...")
//        case .playbackLikelyToKeepUp:
//            print("Playback likely to keep up")
//        case .statusChanged:
//            if playerItem.status == .readyToPlay {
//                print("Ready to play")
//                player.play()
//            }
//        case .none:
//            break
//        }
//    }
//    
//    // Observe player status and time control status
//    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
//        if keyPath == "status" {
//            if player.status == .readyToPlay {
//                print("Player status: ready to play")
//            } else if player.status == .failed {
//                print("Player status: failed")
//            }
//        } else if keyPath == "timeControlStatus" {
//            if player.timeControlStatus == .paused {
//                print("Player is paused")
//            } else if player.timeControlStatus == .waitingToPlayAtSpecifiedRate {
//                print("Player is waiting to play at specified rate")
//            } else if player.timeControlStatus == .playing {
//                print("Player is playing")
//            }
//        }
//    }
//    
//    deinit {
//        player.removeObserver(self, forKeyPath: "status")
//        player.removeObserver(self, forKeyPath: "timeControlStatus")
//    }
//}
//








import UIKit
import AVKit

class ViewController: UIViewController, CachingPlayerItemDelegate, CachingPlayerItemStateDelegate {

    var playerViewController: AVPlayerViewController!
    var player: AVPlayer!
    var cacheManager = CacheManager.shared

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Initialize AVPlayerViewController
        playerViewController = AVPlayerViewController()
        playerViewController.view.frame = view.bounds
        addChild(playerViewController)
        view.addSubview(playerViewController.view)
        
        // HLS URL (default)
        let baseURLString = "https://storage.googleapis.com/zingcam/flam/prod/streaming/Combo/hls/"
        let initialURLString = "master_combo.m3u8" // Default to master playlist
        
        guard let initialURL = URL(string: baseURLString + initialURLString) else {
            fatalError("Invalid initial URL")
        }
        
        // Initialize AVPlayer with initial URL
        let cachingPlayerItem = CachingPlayerItem(url: initialURL)
        cachingPlayerItem.delegate = self
        cachingPlayerItem.stateDelegate = self
        
        player = AVPlayer(playerItem: cachingPlayerItem)
        playerViewController.player = player
        
        // Start playing automatically
        player.play()
        
        // Add resolution change buttons
        addResolutionButtons()
        
        // Initialize reachability
        cacheManager.startReachability()
        
        // Add observer for player's status
        player.addObserver(self, forKeyPath: "status", options: [.new, .old], context: nil)
        player.addObserver(self, forKeyPath: "timeControlStatus", options: [.new, .old], context: nil)
    }
    
    func addResolutionButtons() {
        let buttonTitles = ["Auto", "1080p", "720p", "480p", "360p"]
        let buttonWidth = view.frame.width / CGFloat(buttonTitles.count)
        
        for (index, title) in buttonTitles.enumerated() {
            let button = UIButton(frame: CGRect(x: buttonWidth * CGFloat(index), y: view.frame.height - 100, width: buttonWidth, height: 50))
            button.backgroundColor = .darkGray
            button.setTitle(title, for: .normal)
            button.tag = index
            button.addTarget(self, action: #selector(changeResolution(_:)), for: .touchUpInside)
            view.addSubview(button)
        }
    }
    
    var currentValue: String = ""
    var resolution: String = ""
//    @objc func changeResolution(_ sender: UIButton) {
//        let baseURLString = "https://storage.googleapis.com/zingcam/flam/prod/streaming/Combo/hls/"
//        
//        var resolutionURLString: String
//        
//        switch sender.tag {
//        case 0: // Auto (use the original master playlist)
//            resolutionURLString = "master_combo.m3u8"
//        case 1: // 1080p
//            resolutionURLString = "1080p/stream.m3u8"
//        case 2: // 720p
//            resolutionURLString = "720p/stream.m3u8"
//        case 3: // 480p
//            resolutionURLString = "480p/stream.m3u8"
//        case 4: // 360p
//            resolutionURLString = "360p/stream.m3u8"
//        default:
//            return
//        }
//        currentValue = resolutionURLString
//        
//        guard let url = URL(string: baseURLString + resolutionURLString) else { return }
//        
//        // Check if the item is cached
//        if let cachingPlayerItem = cacheManager.cacheItems[resolutionURLString] {
//            // Use cached item
//            guard let cacheDirectory = getCacheDirectory() else {
//                return
//            }
//                
//            let filePath = cacheDirectory.path + "/" + currentValue
//            print("Cache Directory: \(filePath)")
//            let fileURL = URL(fileURLWithPath: filePath)
//            let fileManager = FileManager.default
//            if fileManager.fileExists(atPath: fileURL.path) {
//                print("File exists at: \(fileURL.path)")
//            } else {
//                print("File does not exist at: \(fileURL.path)")
//            }
//            player = AVPlayer(url: fileURL)
//            
//            print("Playing from cache for resolution: \(sender.titleLabel?.text ?? "Unknown")")
//            
//            // Start playing automatically
//            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0){
//                print("CHECK VIDEO STATUS: \(self.player.status)")
//                self.player.play()
//            }
//        } else {
//            // Create new caching player item
//            let cachingPlayerItem = CachingPlayerItem(url: url)
//            cachingPlayerItem.fetchAllSegments(from: url)
//            cachingPlayerItem.delegate = self
//            cachingPlayerItem.stateDelegate = self
//            
//            // Cache the item
//            cacheManager.cacheItems[resolutionURLString] = cachingPlayerItem
//            cachingPlayerItem.download()
//            
//            // Replace current AVPlayerItem with the new caching player item
//            player.replaceCurrentItem(with: cachingPlayerItem)
//            
//            // Start playing automatically
//            player.play()
//        }
//    }
    
    
    @objc func changeResolution(_ sender: UIButton) {
        let baseURLString = "https://storage.googleapis.com/zingcam/flam/prod/streaming/Combo/hls/"
        
        var resolutionURLString: String
        
        switch sender.tag {
        case 0: // Auto (use the original master playlist)
            resolutionURLString = "master_combo.m3u8"
        case 1: // 1080p
            resolutionURLString = "1080p/stream.m3u8"
            resolution = "1080p/"
        case 2: // 720p
            resolutionURLString = "720p/stream.m3u8"
            resolution = "720p/"
        case 3: // 480p
            resolutionURLString = "480p/stream.m3u8"
            resolution = "480p/"
        case 4: // 360p
            resolutionURLString = "360p/stream.m3u8"
            resolution = "360p/"
        default:
            return
        }
        currentValue = resolutionURLString
        
        guard let url = URL(string: baseURLString + resolutionURLString) else { return }
        
        // Check if the item is cached
        if let cachedItem = cacheManager.cacheItems[resolutionURLString] {
            // Use cached item
            guard let cacheDirectory = getCacheDirectory() else { return }
            let filePath = cacheDirectory.path + "/" + resolutionURLString
            let fileURL = URL(fileURLWithPath: filePath)
            let fileManager = FileManager.default
            
            if fileManager.fileExists(atPath: fileURL.path) {
                print("File exists at: \(fileURL.path)")
                print("Playing from cache for resolution: \(sender.titleLabel?.text ?? "Unknown")")
                
                
                
                let asset = AVURLAsset(url: fileURL)
                let cachedPlayerItem = AVPlayerItem(asset: asset)
                player.replaceCurrentItem(with: cachedPlayerItem)
                print("cachedPlayerItem: \(cachedPlayerItem)")
                print(" file url that will play: \(fileURL)")
                
                if checkFileExists(atPath: fileURL.path) {
                    print("check The file exists at \(fileURL.path).")
                } else {
                    print("check The file does not exist at \(fileURL.path).")
                }
                
                // Start playing automatically
                DispatchQueue.main.async {
                    self.player.play()
                }
                return
            } else {
                print("File does not exist at: \(fileURL.path)")
            }
        }
        
        func checkFileExists(atPath path: String) -> Bool {
            let fileManager = FileManager.default
            return fileManager.fileExists(atPath: path)
        }
        
        // Create new caching player item
        let cachingPlayerItem = CachingPlayerItem(url: url)
        cachingPlayerItem.fetchAllSegments(from: url)
        cachingPlayerItem.delegate = self
        cachingPlayerItem.stateDelegate = self
        
        // Cache the item
        cacheManager.cacheItems[resolutionURLString] = cachingPlayerItem
        cachingPlayerItem.download()
        
        // Replace current AVPlayerItem with the new caching player item
        player.replaceCurrentItem(with: cachingPlayerItem)
        
        // Start playing automatically
        player.play()
    }
    
    // CachingPlayerItemDelegate methods
    func playerItem(_ playerItem: CachingPlayerItem, didFinishDownloadingData data: Data) {
        print("File is downloaded and ready for storing")
        guard let cacheDirectory = getCacheDirectory() else { return }
        let filePath = cacheDirectory.path + "/" + currentValue
        let fileURL = URL(fileURLWithPath: filePath)
        
//        do {
//            try data.write(to: fileURL)
//            print("File saved at: \(fileURL.path)")
//        } catch {
//            print("Failed to save file: \(error.localizedDescription)")
//        }
        
        CacheManager.shared.storage?.async.setObject(data, forKey: playerItem.url.absoluteString, completion: { _ in })
        print("Data size: \(data.count) bytes")
        print("Player URL: \(playerItem.url.absoluteString)")
    }
    
    func playerItem(_ playerItem: CachingPlayerItem, didDownloadBytesSoFar bytesDownloaded: Int, outOf bytesExpected: Int) {
        print("\(bytesDownloaded)/\(bytesExpected)")
    }
    
    func playerItemPlaybackStalled(_ playerItem: CachingPlayerItem) {
        print("Playback stalled, buffering...")
        
        // Check if the stalled segment is available in cache
        do {
            if let cachedData = try CacheManager.shared.storage?.object(forKey: playerItem.url.absoluteString) {
                print("Using cached data")
                let asset = AVURLAsset(url: playerItem.url)
                let newItem = AVPlayerItem(asset: asset)
                player.replaceCurrentItem(with: newItem)
                player.play()
            }
        } catch {
            print("Error retrieving cached data: \(error.localizedDescription)")
        }
    }
    
    func playerItem(_ playerItem: CachingPlayerItem, downloadingFailedWith error: Error) {
        print("Downloading failed: \(error.localizedDescription)")
        let newItem = AVPlayerItem(url: playerItem.url)
        player.replaceCurrentItem(with: newItem)
        player.play()
    }
    
    // CachingPlayerItemStateDelegate methods
    func playerItemStateChange(_ playerItem: CachingPlayerItem, changedTo state: CachingPlayerItemState) {
        switch state {
        case .playbackBufferEmpty:
            print("Buffering...")
        case .playbackLikelyToKeepUp:
            print("Playback likely to keep up")
        case .statusChanged:
            if playerItem.status == .readyToPlay {
                print("Ready to play")
                player.play()
            }
        case .none:
            break
        }
    }
    
    // Observe player status and time control status
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "status" {
            if player.status == .readyToPlay {
                print("Player status: ready to play")
            } else if player.status == .failed {
                print("Player status: failed")
            }
        } else if keyPath == "timeControlStatus" {
            if player.timeControlStatus == .paused {
                print("Player is paused")
            } else if player.timeControlStatus == .waitingToPlayAtSpecifiedRate {
                print("Player is waiting to play at specified rate")
            } else if player.timeControlStatus == .playing {
                print("Player is playing")
            }
        }
    }
    
    deinit {
        player.removeObserver(self, forKeyPath: "status")
        player.removeObserver(self, forKeyPath: "timeControlStatus")
    }
}

func getCacheDirectory() -> URL? {
    let fileManager = FileManager.default
    do {
        let cacheDirectory = try fileManager.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
        return cacheDirectory
    } catch {
        print("Error accessing cache directory: \(error)")
        return nil
    }
}

func cacheDirectory() -> URL? {
    return FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
}




