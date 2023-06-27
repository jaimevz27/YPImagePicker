//
//  YPSelectionsVerticalGalleryView.swift
//  
//
//  Created by Degusta Dev on 06/27/23.
//

import UIKit
import Stevia

public class YPSelectionsVerticalGalleryView: UIView {
    
    let collectionView = UICollectionView(frame: .zero, collectionViewLayout: YPGalleryVerticalCollectionViewFlowLayout())
    
    convenience init() {
        self.init(frame: .zero)
    
        subviews(
            collectionView
        )
        
        // Layout collectionView
        //collectionView.heightEqualsWidth()
        collectionView.fillVertically()
        
        if #available(iOS 11.0, *) {
            collectionView.Right == safeAreaLayoutGuide.Right
            collectionView.Left == safeAreaLayoutGuide.Left
        } else {
            |collectionView|
        }
        //collectionView.CenterY == CenterY - 30
        
        // Apply style
        backgroundColor = YPConfig.colors.selectionsBackgroundColor
        collectionView.backgroundColor = .clear
        collectionView.showsHorizontalScrollIndicator = false
    }
}

class YPGalleryVerticalCollectionViewFlowLayout: UICollectionViewFlowLayout {
    
    override init() {
        super.init()
        scrollDirection = .vertical
        let spacing: CGFloat = 12
        minimumLineSpacing = spacing
        minimumInteritemSpacing = spacing
        let screenWidth = YPImagePickerConfiguration.screenWidth
        let height = screenWidth + 40
        itemSize = CGSize(width: screenWidth, height: height)
        sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
