import Foundation
import Cache
import AVFoundation

public class CacheManager {
    
    var cacheItems: [String: CachingPlayerItem] = [String:CachingPlayerItem]()
    
    var currentIndex: Int = 0
    
    public static let shared = CacheManager()
    
    let reachability = try! Reachability()
    
    static var internetStatusChangeNotification = "internetStatusChangeNotification"
    
    var reachabilityStarted = false
    
    public var hasInternet = false
    
    public static var diskCacheSizeInMB: UInt = 500
    
    let diskConfig = DiskConfig(name: "Videos", expiry: .date(Date().addingTimeInterval(2 * 3600)), maxSize: CacheManager.diskCacheSizeInMB * 1024 * 1024, directory: nil, protectionType: nil)
    let memoryConfig = MemoryConfig(expiry: .never, countLimit: CacheManager.memoryCacheItemCount, totalCostLimit: CacheManager.memoryCacheItemCount)
    var storage: Storage<String, Data>?
    
    public static var memoryCacheItemCount: UInt = 100
    
    init() {
        do {
            print("init memory")
            storage = try Storage(diskConfig: diskConfig, memoryConfig: memoryConfig, transformer: TransformerFactory.forCodable(ofType: Data.self))
        } catch {
            print("Error: \(error)")
        }
    }
    
    internal func startReachability() {
        print("start reachability")
        if reachabilityStarted { return }
        reachabilityStarted = true
        
        reachability.whenReachable = { [weak self] reachability in
            self?.hasInternet = true
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: CacheManager.internetStatusChangeNotification), object: nil)
        }
        reachability.whenUnreachable = { [weak self] _ in
            self?.hasInternet = false
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: CacheManager.internetStatusChangeNotification), object: nil)
        }
        
        do {
            try reachability.startNotifier()
        } catch {
            print("Unable to start notifier")
        }
    }
    
//    func save(data: Data, for key: String) {
//        do {
//            print("save")
//            try storage?.setObject(data, forKey: key)
//        } catch {
//            print("Error saving data to cache: \(error)")
//        }
//    }
//    
//    func cachedData(for key: String) -> Data? {
//        do {
//            return try storage?.object(forKey: key)
//        } catch {
//            print("Error retrieving data from cache: \(error)")
//            return nil
//        }
//    }
}


//import Foundation
//import Cache
//
//public class CacheManager {
//    
//    var cacheItems: [String: CachingPlayerItem] = [String: CachingPlayerItem]()
//    var currentIndex: Int = 0
//    
//    public static let shared = CacheManager()
//    
//    let reachability = try! Reachability()
//    static var internetStatusChangeNotification = "internetStatusChangeNotification"
//    
//    var reachabilityStarted = false
//    public var hasInternet = false
//    
//    public static var diskCacheSizeInMB: UInt = 250
//    let diskConfig = DiskConfig(name: "Videos", expiry: .date(Date().addingTimeInterval(2 * 3600)), maxSize: CacheManager.diskCacheSizeInMB * 1024 * 1024, directory: nil, protectionType: nil)
//    let memoryConfig = MemoryConfig(expiry: .never, countLimit: CacheManager.memoryCacheItemCount, totalCostLimit: CacheManager.memoryCacheItemCount)
//    var storage: Storage<String, Data>?
//    
//    public static var memoryCacheItemCount: UInt = 10
//    
//    init() {
//        do {
//            print("init memory")
//            storage = try Storage(diskConfig: diskConfig, memoryConfig: memoryConfig, transformer: TransformerFactory.forCodable(ofType: Data.self))
//        } catch {
//            print("Error: \(error)")
//        }
//    }
//    
//    internal func startReachability() {
//        print("start reachability")
//        if reachabilityStarted { return }
//        reachabilityStarted = true
//        
//        reachability.whenReachable = { [weak self] reachability in
//            self?.hasInternet = true
//            NotificationCenter.default.post(name: NSNotification.Name(rawValue: CacheManager.internetStatusChangeNotification), object: nil)
//        }
//        reachability.whenUnreachable = { [weak self] _ in
//            self?.hasInternet = false
//            NotificationCenter.default.post(name: NSNotification.Name(rawValue: CacheManager.internetStatusChangeNotification), object: nil)
//        }
//        
//        do {
//            try reachability.startNotifier()
//        } catch {
//            print("Unable to start notifier")
//        }
//    }
//    
//    func save(data: Data, for key: String) {
//        do {
//            try storage?.setObject(data, forKey: key)
//        } catch {
//            print("Error saving data to cache: \(error)")
//        }
//    }
//    
//    func cachedData(for key: String) -> Data? {
//        do {
//            return try storage?.object(forKey: key)
//        } catch {
//            print("Error retrieving data from cache: \(error)")
//            return nil
//        }
//    }
//}




//import Foundation
//import Cache
//
//public class CacheManager {
//    
//    var cacheItems: [String: CachingPlayerItem] = [String: CachingPlayerItem]()
//    var currentIndex: Int = 0
//    
//    public static let shared = CacheManager()
//    
//    let reachability = try! Reachability()
//    static var internetStatusChangeNotification = "internetStatusChangeNotification"
//    
//    var reachabilityStarted = false
//    public var hasInternet = false
//    
//    public static var diskCacheSizeInMB: UInt = 250
//    let diskConfig = DiskConfig(name: "Videos", expiry: .date(Date().addingTimeInterval(2 * 3600)), maxSize: CacheManager.diskCacheSizeInMB * 1024 * 1024, directory: nil, protectionType: nil)
//    let memoryConfig = MemoryConfig(expiry: .never, countLimit: CacheManager.memoryCacheItemCount, totalCostLimit: CacheManager.memoryCacheItemCount)
//    var storage: Storage<String, Data>?
//    
//    public static var memoryCacheItemCount: UInt = 10
//    
//    init() {
//        do {
//            print("init memory")
//            storage = try Storage(diskConfig: diskConfig, memoryConfig: memoryConfig, transformer: TransformerFactory.forCodable(ofType: Data.self))
//        } catch {
//            print("Error: \(error)")
//        }
//    }
//    
//    internal func startReachability() {
//        print("start reachability")
//        if reachabilityStarted { return }
//        reachabilityStarted = true
//        
//        reachability.whenReachable = { [weak self] reachability in
//            self?.hasInternet = true
//            NotificationCenter.default.post(name: NSNotification.Name(rawValue: CacheManager.internetStatusChangeNotification), object: nil)
//        }
//        reachability.whenUnreachable = { [weak self] _ in
//            self?.hasInternet = false
//            NotificationCenter.default.post(name: NSNotification.Name(rawValue: CacheManager.internetStatusChangeNotification), object: nil)
//        }
//        
//        do {
//            try reachability.startNotifier()
//        } catch {
//            print("Unable to start notifier")
//        }
//    }
//    
//    func save(data: Data, for key: String) {
//        do {
//            try storage?.setObject(data, forKey: key)
//            print("Data successfully saved to cache for key: \(key)")
//        } catch {
//            print("Error saving data to cache: \(error)")
//        }
//    }
//    
//    func cachedData(for key: String) -> Data? {
//        do {
//            let data = try storage?.object(forKey: key)
//            print("Data successfully retrieved from cache for key: \(key)")
//            return data
//        } catch {
//            print("Error retrieving data from cache: \(error)")
//            return nil
//        }
//    }
//    
//    // Save data to local storage
//    func saveToLocalStorage(data: Data, for key: String) {
//        let fileURL = getLocalFileURL(for: key)
//        do {
//            try data.write(to: fileURL)
//            print("Data successfully saved to local storage at: \(fileURL.path)")
//        } catch {
//            print("Error saving data to local storage: \(error)")
//        }
//    }
//    
//    // Retrieve data from local storage
//    func localData(for key: String) -> Data? {
//        let fileURL = getLocalFileURL(for: key)
//        do {
//            let data = try Data(contentsOf: fileURL)
//            print("Data successfully retrieved from local storage at: \(fileURL.path)")
//            return data
//        } catch {
//            print("Error retrieving data from local storage: \(error)")
//            return nil
//        }
//    }
//    
//    private func getLocalFileURL(for key: String) -> URL {
//        let fileName = key.replacingOccurrences(of: "/", with: "_") // Replace slashes in key with underscores
//        let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
//        return documentDirectory.appendingPathComponent(fileName)
//    }
//}

