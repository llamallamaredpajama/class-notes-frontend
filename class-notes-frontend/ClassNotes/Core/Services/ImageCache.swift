// 1. Standard library
import Foundation

// 2. Apple frameworks
import UIKit
import SwiftUI
import Combine
import os.log

/// A thread-safe image cache with memory and disk caching
@MainActor
class ImageCache: ObservableObject {
    // MARK: - Properties
    
    static let shared = ImageCache()
    
    private let memoryCache = NSCache<NSString, UIImage>()
    private let diskCache: URLCache
    private let session: URLSession
    private var cancellables = Set<AnyCancellable>()
    
    @Published var isLoading = false
    
    // MARK: - Cache Configuration
    
    private let maxMemoryCost = 50 * 1024 * 1024 // 50 MB
    private let maxDiskCacheSize = 200 * 1024 * 1024 // 200 MB
    private let cacheDirectory: URL
    
    // MARK: - Initialization
    
    private init() {
        // Configure memory cache
        memoryCache.totalCostLimit = maxMemoryCost
        memoryCache.countLimit = 100
        
        // Configure disk cache
        let cachesURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        cacheDirectory = cachesURL.appendingPathComponent("ImageCache")
        
        // Create cache directory if needed
        try? FileManager.default.createDirectory(
            at: cacheDirectory,
            withIntermediateDirectories: true,
            attributes: nil
        )
        
        diskCache = URLCache(
            memoryCapacity: 10 * 1024 * 1024, // 10 MB
            diskCapacity: maxDiskCacheSize,
            directory: cacheDirectory
        )
        
        // Configure session
        let configuration = URLSessionConfiguration.default
        configuration.urlCache = diskCache
        configuration.requestCachePolicy = .returnCacheDataElseLoad
        session = URLSession(configuration: configuration)
        
        // Listen for memory warnings
        NotificationCenter.default.publisher(for: UIApplication.didReceiveMemoryWarningNotification)
            .sink { [weak self] _ in
                self?.clearMemoryCache()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Public Methods
    
    /// Load image from URL with caching
    func loadImage(from url: URL) async throws -> UIImage {
        let key = url.absoluteString as NSString
        
        // Check memory cache first
        if let cachedImage = memoryCache.object(forKey: key) {
            return cachedImage
        }
        
        // Check disk cache
        if let diskImage = loadImageFromDisk(url: url) {
            // Store in memory cache
            memoryCache.setObject(diskImage, forKey: key, cost: diskImage.diskSize)
            return diskImage
        }
        
        // Download image
        isLoading = true
        defer { isLoading = false }
        
        let (data, response) = try await session.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode),
              let image = UIImage(data: data) else {
            throw ImageCacheError.invalidImageData
        }
        
        // Cache image
        cacheImage(image, for: url)
        
        return image
    }
    
    /// Preload images for URLs
    func preloadImages(urls: [URL]) async {
        await withTaskGroup(of: Void.self) { group in
            for url in urls {
                group.addTask { [weak self] in
                    _ = try? await self?.loadImage(from: url)
                }
            }
        }
    }
    
    /// Remove specific image from cache
    func removeImage(for url: URL) {
        let key = url.absoluteString as NSString
        memoryCache.removeObject(forKey: key)
        removeImageFromDisk(url: url)
    }
    
    /// Clear all caches
    func clearCache() {
        clearMemoryCache()
        clearDiskCache()
    }
    
    /// Clear memory cache only
    func clearMemoryCache() {
        memoryCache.removeAllObjects()
    }
    
    /// Clear disk cache only
    func clearDiskCache() {
        diskCache.removeAllCachedResponses()
        try? FileManager.default.removeItem(at: cacheDirectory)
        try? FileManager.default.createDirectory(
            at: cacheDirectory,
            withIntermediateDirectories: true,
            attributes: nil
        )
    }
    
    /// Get cache size
    func getCacheSize() async -> Int64 {
        let diskSize = await Task.detached { [weak self] in
            self?.calculateDiskCacheSize() ?? 0
        }.value
        
        return diskSize
    }
    
    // MARK: - Private Methods
    
    private func cacheImage(_ image: UIImage, for url: URL) {
        let key = url.absoluteString as NSString
        
        // Store in memory cache
        memoryCache.setObject(image, forKey: key, cost: image.diskSize)
        
        // Store on disk
        saveImageToDisk(image, url: url)
    }
    
    private func saveImageToDisk(_ image: UIImage, url: URL) {
        let filename = url.lastPathComponent.isEmpty ? UUID().uuidString : url.lastPathComponent
        let fileURL = cacheDirectory.appendingPathComponent(filename)
        
        if let data = image.jpegData(compressionQuality: 0.8) {
            try? data.write(to: fileURL)
        }
    }
    
    private func loadImageFromDisk(url: URL) -> UIImage? {
        let filename = url.lastPathComponent.isEmpty ? UUID().uuidString : url.lastPathComponent
        let fileURL = cacheDirectory.appendingPathComponent(filename)
        
        guard let data = try? Data(contentsOf: fileURL),
              let image = UIImage(data: data) else {
            return nil
        }
        
        return image
    }
    
    private func removeImageFromDisk(url: URL) {
        let filename = url.lastPathComponent.isEmpty ? UUID().uuidString : url.lastPathComponent
        let fileURL = cacheDirectory.appendingPathComponent(filename)
        try? FileManager.default.removeItem(at: fileURL)
    }
    
    nonisolated private func calculateDiskCacheSize() -> Int64 {
        let fileManager = FileManager.default
        var size: Int64 = 0
        
        if let files = try? fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: [.fileSizeKey]) {
            for file in files {
                if let fileSize = try? file.resourceValues(forKeys: [.fileSizeKey]).fileSize {
                    size += Int64(fileSize)
                }
            }
        }
        
        return size
    }
}

// MARK: - SwiftUI View Extension

extension View {
    /// Modifier to load and cache remote images
    func cachedImage(url: URL?, placeholder: Image = Image(systemName: "photo")) -> some View {
        self.modifier(CachedImageModifier(url: url, placeholder: placeholder))
    }
}

// MARK: - Cached Image View Modifier

struct CachedImageModifier: ViewModifier {
    let url: URL?
    let placeholder: Image
    
    @State private var image: UIImage?
    @State private var isLoading = false
    
    func body(content: Content) -> some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
            } else if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                placeholder
                    .foregroundColor(.secondary)
            }
        }
        .task {
            await loadImage()
        }
    }
    
    private func loadImage() async {
        guard let url = url else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            image = try await ImageCache.shared.loadImage(from: url)
        } catch {
            os_log("Failed to load image: %@", log: OSLog.default, type: .error, error.localizedDescription)
        }
    }
}

// MARK: - Async Image View

/// A view that asynchronously loads and displays an image with caching
struct CachedAsyncImage: View {
    // MARK: - Properties
    
    let url: URL?
    let placeholder: Image
    
    @State private var image: UIImage?
    @State private var isLoading = false
    
    // MARK: - Initialization
    
    init(url: URL?, placeholder: Image = Image(systemName: "photo")) {
        self.url = url
        self.placeholder = placeholder
    }
    
    // MARK: - Body
    
    var body: some View {
        GeometryReader { geometry in
            Group {
                if let image = image {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .clipped()
                } else if isLoading {
                    ProgressView()
                        .frame(width: geometry.size.width, height: geometry.size.height)
                } else {
                    placeholder
                        .foregroundColor(.secondary)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                }
            }
        }
        .task {
            await loadImage()
        }
    }
    
    // MARK: - Methods
    
    private func loadImage() async {
        guard let url = url else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            image = try await ImageCache.shared.loadImage(from: url)
        } catch {
            os_log("Failed to load image: %@", log: OSLog.default, type: .error, error.localizedDescription)
        }
    }
}

// MARK: - Error Types

enum ImageCacheError: LocalizedError {
    case invalidImageData
    case networkError(Error)
    case diskError(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidImageData:
            return "Invalid image data received"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .diskError(let error):
            return "Disk error: \(error.localizedDescription)"
        }
    }
}

// MARK: - UIImage Extension

extension UIImage {
    /// Calculate approximate disk size of image
    var diskSize: Int {
        guard let cgImage = cgImage else { return 0 }
        return cgImage.bytesPerRow * cgImage.height
    }
} 