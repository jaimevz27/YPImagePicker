//
//  YPSelectionsVerticalGalleryVC.swift
//  
//
//  Created by Degusta Dev on 06/27/23.
//

import UIKit

public class YPSelectionsVerticalGalleryVC: UIViewController, YPSelectionsVerticalGalleryCellDelegate {
    
    override public var prefersStatusBarHidden: Bool { return YPConfig.hidesStatusBar }
    
    public var items: [YPMediaItem] = []
    public var didFinishHandler: ((_ gallery: YPSelectionsVerticalGalleryVC, _ items: [YPMediaItem]) -> Void)?
    private var lastContentOffsetX: CGFloat = 0
    
    var v = YPSelectionsVerticalGalleryView()
    public override func loadView() { view = v }

    public required init(items: [YPMediaItem],
                         didFinishHandler:
        @escaping ((_ gallery: YPSelectionsVerticalGalleryVC, _ items: [YPMediaItem]) -> Void)) {
        super.init(nibName: nil, bundle: nil)
        self.items = items
        self.didFinishHandler = didFinishHandler
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()

        // Register collection view cell
        v.collectionView.register(YPSelectionsVerticalGalleryCell.self, forCellWithReuseIdentifier: "item")
        v.collectionView.dataSource = self
        v.collectionView.delegate = self
        
        // Setup navigation bar
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: YPConfig.wordings.next,
                                                            style: .done,
                                                            target: self,
                                                            action: #selector(done))
        navigationItem.rightBarButtonItem?.tintColor = YPConfig.colors.tintColor
        navigationItem.rightBarButtonItem?.setFont(font: YPConfig.fonts.rightBarButtonFont, forState: .disabled)
        navigationItem.rightBarButtonItem?.setFont(font: YPConfig.fonts.rightBarButtonFont, forState: .normal)
        navigationController?.navigationBar.setTitleFont(font: YPConfig.fonts.navigationBarTitleFont)
        
        YPHelper.changeBackButtonIcon(self)
        YPHelper.changeBackButtonTitle(self)
    }

    @objc
    private func done() {
        // Save new images to the photo album.
        if YPConfig.shouldSaveNewPicturesToAlbum {
            for m in items {
                if case let .photo(p) = m, let modifiedImage = p.modifiedImage {
                    YPPhotoSaver.trySaveImage(modifiedImage, inAlbumNamed: YPConfig.albumName)
                }
            }
        }
        didFinishHandler?(self, items)
    }
    
    public func selectionsVerticalGalleryCellDidTapRemove(cell: YPSelectionsVerticalGalleryCell) {
        if let indexPath = v.collectionView.indexPath(for: cell) {
            items.remove(at: indexPath.row)
            v.collectionView.performBatchUpdates({
                v.collectionView.deleteItems(at: [indexPath])
            }, completion: { _ in })
        }
    }
}

// MARK: - Collection View
extension YPSelectionsVerticalGalleryVC: UICollectionViewDataSource {
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return items.count
    }
    
    public func collectionView(_ collectionView: UICollectionView,
                               cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "item",
                                                            for: indexPath) as? YPSelectionsVerticalGalleryCell else {
            return UICollectionViewCell()
        }
        cell.delegate = self
        let item = items[indexPath.row]
        switch item {
        case .photo(let photo):
            cell.imageView.image = photo.image
            cell.setEditable(YPConfig.showsPhotoFilters)
        case .video(let video):
            cell.imageView.image = video.thumbnail
            cell.setEditable(YPConfig.showsVideoTrimmer)
        }
        cell.removeButton.isHidden = YPConfig.gallery.hidesRemoveButton
        return cell
    }
}

extension YPSelectionsVerticalGalleryVC: UICollectionViewDelegate {
    
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let item = items[indexPath.row]
        var mediaFilterVC: IsMediaFilterVC?
        switch item {
        case .photo(let photo):
            if !YPConfig.filters.isEmpty, YPConfig.showsPhotoFilters {
                mediaFilterVC = YPPhotoFiltersVC(inputPhoto: photo, isFromSelectionVC: true)
            }
        case .video(let video):
            if YPConfig.showsVideoTrimmer {
                mediaFilterVC = YPVideoFiltersVC.initWith(video: video, isFromSelectionVC: true)
            }
        }
        
        mediaFilterVC?.didSave = { outputMedia in
            self.items[indexPath.row] = outputMedia
            collectionView.reloadData()
            self.dismiss(animated: true, completion: nil)
        }
        mediaFilterVC?.didCancel = {
            self.dismiss(animated: true, completion: nil)
        }
        if let mediaFilterVC = mediaFilterVC as? UIViewController {
            let navVC = UINavigationController(rootViewController: mediaFilterVC)
            navVC.navigationBar.isTranslucent = false
            navVC.navigationBar.backgroundColor = YPConfig.colors.defaultNavigationBarColor
            present(navVC, animated: true, completion: nil)
        }
    }
}
