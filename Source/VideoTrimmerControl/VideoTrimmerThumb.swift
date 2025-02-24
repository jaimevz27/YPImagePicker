//
//  VideoTrimmerThumb.swift
//  VideoTrimmer
//
//  Created by Andreas Verhoeven on 02/09/2020.
//  Copyright © 2020 Andreas Verhoeven. All rights reserved.
//

import UIKit

class VideoTrimmerThumb: UIView {
    var isActive = false {
        didSet {
            
            self.setNeedsLayout()
            
            if isActive {
                updateColor()
            } else {
                setIdleColor()
            }
        }
    }

	var leadingChevronImageView = UIImageView(image: imageFromBundle("vtc_chevron_left"))
	var trailingChevronView = UIImageView(image: imageFromBundle("vtc_chevron_right"))

	var wrapperView = UIView()
	var leadingView = UIView()
	var trailingView = UIView()
	var topView = UIView()
	var bottomView = UIView()

	let leadingGrabber = UIControl()
	let trailingGrabber = UIControl()

	let chevronWidth = CGFloat(16)
	let edgeHeight = CGFloat(4)

	// MARK: - Input
	@objc private func x(_ sender: Any) {

	}

	// MARK: - Private
	public func updateColor() {
		let color = YPConfig.colors.trimmerMainSelectedColor
		leadingView.backgroundColor = color
		trailingView.backgroundColor = color
		topView.backgroundColor = color
		bottomView.backgroundColor = color
        
        leadingChevronImageView.tintColor = YPConfig.colors.trimmerHandleSelectedColor
        leadingChevronImageView.tintAdjustmentMode = .normal
        
        trailingChevronView.tintColor = YPConfig.colors.trimmerHandleSelectedColor
        trailingChevronView.tintAdjustmentMode = .normal
        
        self.layoutIfNeeded()
	}
    
    public func setIdleColor() {
        let color = YPConfig.colors.trimmerMainColor
        leadingView.backgroundColor = color
        trailingView.backgroundColor = color
        topView.backgroundColor = color
        bottomView.backgroundColor = color
        
        leadingChevronImageView.tintColor = YPConfig.colors.trimmerHandleColor
        leadingChevronImageView.tintAdjustmentMode = .normal
        
        trailingChevronView.tintColor = YPConfig.colors.trimmerHandleColor
        trailingChevronView.tintAdjustmentMode = .normal
        
        self.layoutIfNeeded()
    }

	private func setup() {

		leadingChevronImageView.contentMode = .scaleAspectFill
		trailingChevronView.contentMode = .scaleAspectFill

		leadingView.layer.cornerRadius = 6
        if #available(iOS 13.0, *) {
            leadingView.layer.cornerCurve = .continuous
        }
		leadingView.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMinXMinYCorner]

		trailingView.layer.cornerRadius = 6
        if #available(iOS 13.0, *) {
            trailingView.layer.cornerCurve = .continuous
        }
		trailingView.layer.maskedCorners = [.layerMaxXMaxYCorner, .layerMaxXMinYCorner]

		leadingView.addSubview(leadingChevronImageView)
		trailingView.addSubview(trailingChevronView)

		//		wrapperView.layer.shadowColor = UIColor.black.cgColor
		//		wrapperView.layer.shadowOffset = .zero
		//		wrapperView.layer.shadowRadius = 2
		//		wrapperView.layer.shadowOpacity = 0.25

		wrapperView.addSubview(leadingView)
		wrapperView.addSubview(trailingView)
		wrapperView.addSubview(topView)
		wrapperView.addSubview(bottomView)
		addSubview(wrapperView)

		wrapperView.addSubview(leadingGrabber)
		wrapperView.addSubview(trailingGrabber)

        setIdleColor()
	}



	// MARK: - UIView

	override func layoutSubviews() {
		super.layoutSubviews()

		let size = bounds.size

		wrapperView.frame = CGRect(origin: .zero, size: size)

		leadingView.frame = CGRect(x: 0, y: 0, width: chevronWidth, height: bounds.height)
		trailingView.frame = CGRect(x: bounds.width - chevronWidth, y: 0, width: chevronWidth, height: bounds.height)
		topView.frame = CGRect(x: chevronWidth, y: 0, width: bounds.width - chevronWidth * 2, height: edgeHeight)
		bottomView.frame = CGRect(x: chevronWidth, y: bounds.height - edgeHeight, width: bounds.width - chevronWidth * 2, height: edgeHeight)

		let chevronHorizontalInset = CGFloat(2)
		let chevronVerticalInset = CGFloat(8)
		let chevronFrame = CGRect(x: chevronHorizontalInset, y: chevronVerticalInset, width: chevronWidth - chevronHorizontalInset * 2, height: size.height - chevronVerticalInset * 2)

		leadingChevronImageView.frame = chevronFrame
		trailingChevronView.frame = chevronFrame

		leadingGrabber.frame = leadingView.frame
		trailingGrabber.frame = trailingView.frame
	}

	override init(frame: CGRect) {
		super.init(frame: frame)
		setup()
	}

	required init?(coder: NSCoder) {
		super.init(coder: coder)
		setup()
	}
}

