// The MIT License (MIT)
//
// Copyright (c) 2015 Joakim Gyllström
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

import UIKit
import Photos

/**
BSImagePickerViewController.
Use settings or buttons to customize it to your needs.
*/
open class BSImagePickerViewController : UINavigationController {
    /**
     Object that keeps settings for the picker.
     */
    open var settings: BSImagePickerSettings = Settings()
    
    /**
     Done button.
     */
    @objc open var doneButton: UIBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: nil, action: nil)
    
    /**
     Cancel button
     */
    @objc open var cancelButton: UIBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: nil, action: nil)
    
    /**
     Default selections
     */
    @objc open var defaultSelections: [PHAsset]?
    
    /**
     Fetch results.
     */
    
    @objc open lazy var fetchResults: [PHFetchResult] = { () -> [PHFetchResult<PHAssetCollection>] in
        let fetchOptions = PHFetchOptions()

        var result: [PHFetchResult<PHAssetCollection>] = []
        
        // Camera roll fetch result
        result.append(PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .smartAlbumUserLibrary, options: fetchOptions))
        
        if let value = fetchAssetCollections(with: .smartAlbum, subtype: .smartAlbumFavorites, options: fetchOptions) {
            result.append(value)
        }
        
        if #available(iOS 9.0, *) {
            if let value = fetchAssetCollections(with: .smartAlbum, subtype: .smartAlbumSelfPortraits, options: fetchOptions) {
                result.append(value)
            }
            if let value = fetchAssetCollections(with: .smartAlbum, subtype: .smartAlbumScreenshots, options: fetchOptions) {
                result.append(value)
            }
        }
        if #available(iOS 10.2, *) {
            if let value = fetchAssetCollections(with: .smartAlbum, subtype: .smartAlbumDepthEffect, options: fetchOptions) {
                result.append(value)
            }
        }

        if #available(iOS 10.3, *) {
            if let value = fetchAssetCollections(with: .smartAlbum, subtype: .smartAlbumLivePhotos, options: fetchOptions) {
                result.append(value)
            }
        }

        if #available(iOS 11.0, *) {
            if let value = fetchAssetCollections(with: .smartAlbum, subtype: .smartAlbumAnimated, options: fetchOptions) {
                result.append(value)
            }
            if let value = fetchAssetCollections(with: .smartAlbum, subtype: .smartAlbumLongExposures, options: fetchOptions) {
                result.append(value)
            }
        }

        fetchOptions.predicate = NSPredicate(format: "estimatedAssetCount > 0")
        result.append(PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: fetchOptions))

        return result
    }()
    
    private func fetchAssetCollections(with type: PHAssetCollectionType, subtype: PHAssetCollectionSubtype, options: PHFetchOptions?) -> PHFetchResult<PHAssetCollection>? {
        let result = PHAssetCollection.fetchAssetCollections(with: type, subtype: subtype, options: options)

        if let obj = result.firstObject, obj.photosCount > 0 {
            return result
        }
        return nil
    }
    
    @objc var albumTitleView: UIButton = {
        let btn =  UIButton(frame: .zero)
        btn.setTitleColor(UIColor(red: 145.0 / 255.0, green: 205.0 / 255.0, blue: 225.0 / 255.0, alpha: 1.0), for: .normal)
        return btn
    }()
    
    @objc static let bundle: Bundle = Bundle(path: Bundle(for: PhotosViewController.self).path(forResource: "BSImagePicker", ofType: "bundle")!)!
    
    @objc lazy var photosViewController: PhotosViewController = {
        let vc = PhotosViewController(fetchResults: self.fetchResults,
                                      defaultSelections: self.defaultSelections,
                                      settings: self.settings)
        
        vc.doneBarButton = self.doneButton
        vc.cancelBarButton = self.cancelButton
        vc.albumTitleView = self.albumTitleView
        self.navigationBar.tintColor = UIColor(red: 145.0 / 255.0, green: 205.0 / 255.0, blue: 225.0 / 255.0, alpha: 1.0)
        return vc
    }()
    
    @objc class func authorize(_ status: PHAuthorizationStatus = PHPhotoLibrary.authorizationStatus(), fromViewController: UIViewController, completion: @escaping (_ authorized: Bool) -> Void) {
        switch status {
        case .authorized:
            // We are authorized. Run block
            completion(true)
        case .notDetermined:
            // Ask user for permission
            PHPhotoLibrary.requestAuthorization({ (status) -> Void in
                DispatchQueue.main.async(execute: { () -> Void in
                    self.authorize(status, fromViewController: fromViewController, completion: completion)
                })
            })
        default: ()
            DispatchQueue.main.async(execute: { () -> Void in
                completion(false)
            })
        }
    }
    
    /**
    Sets up an classic image picker with results from camera roll and albums
    */
    public init() {
        super.init(nibName: nil, bundle: nil)
    }

    /**
    https://www.youtube.com/watch?v=dQw4w9WgXcQ
    */
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    /**
    Load view. See apple documentation
    */
    open override func loadView() {
        super.loadView()
        
        // TODO: Settings
        view.backgroundColor = UIColor.white
        
        // Make sure we really are authorized
        if PHPhotoLibrary.authorizationStatus() == .authorized {
            setViewControllers([photosViewController], animated: false)
        }
    }
}

// MARK: ImagePickerSettings proxy
extension BSImagePickerViewController: BSImagePickerSettings {


    /**
     See BSImagePicketSettings for documentation
     */
    @objc public var maxNumberOfSelections: Int {
        get {
            return settings.maxNumberOfSelections
        }
        set {
            settings.maxNumberOfSelections = newValue
        }
    }
    
    /**
     See BSImagePicketSettings for documentation
     */
    public var selectionCharacter: Character? {
        get {
            return settings.selectionCharacter
        }
        set {
            settings.selectionCharacter = newValue
        }
    }
    
    /**
     See BSImagePicketSettings for documentation
     */
    @objc public var selectionFillColor: UIColor {
        get {
            return settings.selectionFillColor
        }
        set {
            settings.selectionFillColor = newValue
        }
    }
    
    /**
     See BSImagePicketSettings for documentation
     */
    @objc public var selectionStrokeColor: UIColor {
        get {
            return settings.selectionStrokeColor
        }
        set {
            settings.selectionStrokeColor = newValue
        }
    }
    
    /**
     See BSImagePicketSettings for documentation
     */
    @objc public var selectionShadowColor: UIColor {
        get {
            return settings.selectionShadowColor
        }
        set {
            settings.selectionShadowColor = newValue
        }
    }
    
    /**
     See BSImagePicketSettings for documentation
     */
    @objc public var selectionTextAttributes: [NSAttributedStringKey: AnyObject] {
        get {
            return settings.selectionTextAttributes
        }
        set {
            settings.selectionTextAttributes = newValue
        }
    }
    
    /**
     BackgroundColor
     */
    @objc public var backgroundColor: UIColor {
        get {
            return settings.backgroundColor
        }
        set {
            settings.backgroundColor = newValue
        }
    }
    
    /**
     See BSImagePicketSettings for documentation
     */
    @objc public var cellsPerRow: (_ verticalSize: UIUserInterfaceSizeClass, _ horizontalSize: UIUserInterfaceSizeClass) -> Int {
        get {
            return settings.cellsPerRow
        }
        set {
            settings.cellsPerRow = newValue
        }
    }
    
    /**
     See BSImagePicketSettings for documentation
     */
    @objc public var takePhotos: Bool {
        get {
            return settings.takePhotos
        }
        set {
            settings.takePhotos = newValue
        }
    }
    
    @objc public var takePhotoIcon: UIImage? {
        get {
            return settings.takePhotoIcon
        }
        set {
            settings.takePhotoIcon = newValue
        }
    }
}

// MARK: Album button
extension BSImagePickerViewController {
    /**
     Album button in title view
     */
    @objc public var albumButton: UIButton {
        get {
            return albumTitleView
        }
        set {
            albumTitleView = newValue
        }
    }
}

extension PHAssetCollection {
    var photosCount: Int {
        let fetchOptions = PHFetchOptions()
        fetchOptions.predicate = NSPredicate(format: "mediaType == %d", PHAssetMediaType.image.rawValue)
        let result = PHAsset.fetchAssets(in: self, options: fetchOptions)
        return result.count
    }
}
