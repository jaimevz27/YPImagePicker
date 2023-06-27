//
//  YPSelectionsVerticalGalleryCell.swift
//  
//
//  Created by Degusta Dev on 06/27/23.
//

import UIKit
import Stevia

public protocol YPSelectionsVerticalGalleryCellDelegate: AnyObject {
    func selectionsVerticalGalleryCellDidTapRemove(cell: YPSelectionsVerticalGalleryCell)
}

public class YPSelectionsVerticalGalleryCell: UICollectionViewCell {
    
    weak var delegate: YPSelectionsVerticalGalleryCellDelegate?
    let imageView = UIImageView()
    let editIcon = UIView()
    let editSquare = UIView()
    let removeButton = UIButton()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    
        subviews(
            imageView,
            editIcon,
            editSquare,
            removeButton
        )
        
        imageView.fillContainer()
        editIcon.size(32).left(12).bottom(12)
        editSquare.size(16)
        editSquare.CenterY == editIcon.CenterY
        editSquare.CenterX == editIcon.CenterX
        
        removeButton.top(12).trailing(12)
        
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.2
        layer.shadowOffset = CGSize(width: 4, height: 7)
        layer.shadowRadius = 5
        layer.backgroundColor = UIColor.clear.cgColor
        imageView.style { i in
            i.clipsToBounds = true
            i.contentMode = .scaleAspectFill
        }
        editIcon.style { v in
            v.backgroundColor = UIColor.ypSystemBackground
            v.layer.cornerRadius = 16
        }
        editSquare.style { v in
            v.layer.borderWidth = 1
            v.layer.borderColor = UIColor.ypLabel.cgColor
        }
        removeButton.setImage(YPConfig.icons.removeImage, for: .normal)
        removeButton.addTarget(self, action: #selector(removeButtonTapped), for: .touchUpInside)
    }
    
    @objc
    func removeButtonTapped() {
        delegate?.selectionsVerticalGalleryCellDidTapRemove(cell: self)
    }
    
    func setEditable(_ editable: Bool) {
        self.editIcon.isHidden = !editable
        self.editSquare.isHidden = !editable
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override var isHighlighted: Bool {
        didSet {
            UIView.animate(withDuration: 0.5,
                           delay: 0,
                           usingSpringWithDamping: 0.5,
                           initialSpringVelocity: 0,
                           options: .curveEaseInOut,
                           animations: {
                            if self.isHighlighted {
                                self.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
                                self.alpha = 0.8
                            } else {
                                self.transform = .identity
                                self.alpha = 1
                            }
            }, completion: nil)
        }
    }
}
