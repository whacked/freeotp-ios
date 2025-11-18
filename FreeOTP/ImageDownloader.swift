//
// FreeOTP
//
// Authors: Nathaniel McCallum <npmccallum@redhat.com>
//
// Copyright (C) 2015  Nathaniel McCallum, Red Hat
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import Foundation
import Photos
import UIKit

class ImageDownloader : NSObject {
    private static let cache = NSCache<NSURL, UIImage>()
    private static let taskQueue = DispatchQueue(label: "org.freeotp.imagedownloader.tasks")
    private static let tasks = NSMapTable<UIImageView, URLSessionDataTask>(keyOptions: .weakMemory, valueOptions: .strongMemory)
    private static let session: URLSession = {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 60
        configuration.requestCachePolicy = .returnCacheDataElseLoad
        return URLSession(configuration: configuration)
    }()

    fileprivate let DEFAULT = UIImage(contentsOfFile: Bundle.main.path(forResource: "default", ofType: "png")!)!
    fileprivate let size: CGSize

    init(_ size: CGSize) {
        self.size = size
        super.init()
    }

    private func cachedImage(for url: URL) -> UIImage? {
        ImageDownloader.cache.object(forKey: url as NSURL)
    }

    private func track(task: URLSessionDataTask?, for imageView: UIImageView) {
        ImageDownloader.taskQueue.sync {
            if let task = task {
                ImageDownloader.tasks.setObject(task, forKey: imageView)
            } else {
                ImageDownloader.tasks.removeObject(forKey: imageView)
            }
        }
    }

    private func currentTask(for imageView: UIImageView) -> URLSessionDataTask? {
        ImageDownloader.taskQueue.sync {
            ImageDownloader.tasks.object(forKey: imageView)
        }
    }

    private func cancelLoad(for imageView: UIImageView) {
        if let task = currentTask(for: imageView) {
            task.cancel()
            track(task: nil, for: imageView)
        }
    }

    func isPHAssetAuthorized(_ status: PHAuthorizationStatus) -> Bool! {
        if #available(iOS 14.0, *) {
            switch status {
            case .denied, .restricted:
                return false
            case .notDetermined:
                return nil
            case .authorized, .limited:
                return true
            @unknown default:
                return false
            }
        } else {
            switch status {
            case .denied, .restricted:
                return false
            case .notDetermined:
                return nil
            case .authorized:
                return true
            @unknown default:
                return false
            }
        }
    }

    func fromPHAsset(_ asset: PHAsset, completion: @escaping (UIImage) -> Void) {
        let opts: PHImageRequestOptions = PHImageRequestOptions()
        opts.isSynchronous = true

        PHImageManager.default().requestImage(
            for: asset,
            targetSize: size,
            contentMode: PHImageContentMode.aspectFill,
            options: opts,
            resultHandler: {
                (image: UIImage?, objects: [AnyHashable: Any]?) -> Void in
                completion(image == nil ? self.DEFAULT : image!)
            }
        )
    }

    func fromALAsset(_ asset: URL, completion: @escaping (UIImage) -> Void) {
        let status = PHPhotoLibrary.authorizationStatus()
        let authorized = isPHAssetAuthorized(status)
        var access_granted = false

        if (authorized == false) {
            // shortcut completion
        } else if (authorized == nil) {
            PHPhotoLibrary.requestAuthorization { (status) -> Void in
                if (self.isPHAssetAuthorized(status) == true) {
                    access_granted = true
                }
            }
        }

        if (authorized == true || access_granted == true) {
            if asset.scheme == "assets-library" {
                let rslt = PHAsset.fetchAssets(withALAssetURLs: [asset], options: nil)
                if rslt.count > 0 {
                    return fromPHAsset(rslt[0] , completion: completion)
                }
            }
        }
        return completion(DEFAULT)
    }

    private func loadRemoteImage(_ url: URL, into imageView: UIImageView, completion: @escaping (UIImage) -> Void) {
        if let cached = cachedImage(for: url) {
            DispatchQueue.main.async {
                imageView.image = cached
                completion(cached)
            }
            return
        }

        cancelLoad(for: imageView)
        DispatchQueue.main.async {
            imageView.image = self.DEFAULT
        }

        var task: URLSessionDataTask?
        task = ImageDownloader.session.dataTask(with: url) { [weak self, weak imageView] data, _, _ in
            guard let self = self, let imageView = imageView, let task = task else { return }
            defer { self.track(task: nil, for: imageView) }

            guard self.currentTask(for: imageView) === task else { return }

            guard let data = data, let image = UIImage(data: data) else {
                DispatchQueue.main.async {
                    imageView.image = self.DEFAULT
                    completion(self.DEFAULT)
                }
                return
            }

            ImageDownloader.cache.setObject(image, forKey: url as NSURL)

            DispatchQueue.main.async {
                imageView.image = image
                completion(image)
            }
        }

        guard let task = task else { return }
        track(task: task, for: imageView)
        task.resume()
    }

    func fromURL(_ url: URL, _ iv: UIImageView, completion: @escaping (UIImage) -> Void) {
        if let scheme = url.scheme {
            switch scheme {
            case "file":
                if let img = UIImage(contentsOfFile: url.path) {
                    return completion(img)
                }

            case "assets-library":
                return fromALAsset(url, completion: completion)

            case "http":
                fallthrough
            case "https":
                loadRemoteImage(url, into: iv, completion: completion)
                return
            default:
                break
            }

            return completion(DEFAULT)
        }
    }

    func fromURI(_ uri: String?, _ iv: UIImageView, completion: @escaping (UIImage) -> Void) {
        if var u = uri {
            if u.hasPrefix("phasset:") {
                let id = String(u[u.index(u.startIndex, offsetBy: "phasset:".count)...])
                let rslt = PHAsset.fetchAssets(withLocalIdentifiers: [id], options: nil)
                if rslt.count > 0 {
                    return fromPHAsset(rslt[0], completion: completion)
                }
            } else {
                // App Transport Security doesn't allow arbitrary loading of
                // HTTP resources any longer.  Most desired images can be
                // retrieved via HTTPS, so just promote URIs to HTTPS.
                if u.hasPrefix("http:") {
                    u.insert("s", at: u.index(u.startIndex, offsetBy: 4))
                }

                if let remote = URL(string: u) {
                    return fromURL(remote, iv, completion: completion)
                }
            }
        }

        return completion(DEFAULT)
    }
}
