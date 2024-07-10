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
//        let cachingPlayerItem = CachingPlayerItem(url: initialURL, resolution: "master")
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
    
    @objc func changeResolution(_ sender: UIButton) {
        let baseURLString = "https://storage.googleapis.com/zingcam/flam/prod/streaming/Combo/hls/"
        
        var resolution: String
        var resolutionURLString: String
        
        switch sender.tag {
        case 0: // Auto (use the original master playlist)
            resolution = "master_combo"
            resolutionURLString = "master_combo.m3u8"
        case 1: // 1080p
            resolution = "1080p"
            resolutionURLString = "1080p/stream.m3u8"
        case 2: // 720p
            resolution = "720p"
            resolutionURLString = "720p/stream.m3u8"
        case 3: // 480p
            resolution = "480p"
            resolutionURLString = "480p/stream.m3u8"
        case 4: // 360p
            resolution = "360p"
            resolutionURLString = "360p/stream.m3u8"
        default:
            return
        }
        
        guard let url = URL(string: baseURLString + resolutionURLString) else { return }
        
        // Check if the item is cached
        if let cachingPlayerItem = cacheManager.cacheItems[resolutionURLString] {
            // Use cached item
            player.replaceCurrentItem(with: cachingPlayerItem)
            
            print("Playing from cache for resolution: \(sender.titleLabel?.text ?? "Unknown")")
            
            // Start playing automatically
            player.play()
        } else {
            // Create new caching player item
//            let cachingPlayerItem = CachingPlayerItem(url: url, resolution: resolution)
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
    }
    
    // CachingPlayerItemDelegate methods
    func playerItem(_ playerItem: CachingPlayerItem, didFinishDownloadingData data: Data) {
        print("File is downloaded and ready for storing")
        CacheManager.shared.storage?.async.setObject(data, forKey: playerItem.url.absoluteString, completion: { _ in })
        print("data: \(data)")
        print("player: \(playerItem.url.absoluteString)")
    }
    
    func playerItem(_ playerItem: CachingPlayerItem, didDownloadBytesSoFar bytesDownloaded: Int, outOf bytesExpected: Int) {
        print("\(bytesDownloaded)/\(bytesExpected)")
    }
    
    func playerItemPlaybackStalled(_ playerItem: CachingPlayerItem) {
        print("Playback stalled, buffering...")
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
}





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

