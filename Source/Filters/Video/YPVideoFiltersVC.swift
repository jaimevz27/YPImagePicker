//
//  VideoFiltersVC.swift
//  YPImagePicker
//
//  Created by Nik Kov || nik-kov.com on 18.04.2018.
//  Copyright © 2018 Yummypets. All rights reserved.
//

import UIKit
import Photos
import PryntTrimmerView
import Stevia

public final class YPVideoFiltersVC: UIViewController, IsMediaFilterVC {

    /// Designated initializer
    public class func initWith(video: YPMediaVideo,
                               isFromSelectionVC: Bool) -> YPVideoFiltersVC {
        let vc = YPVideoFiltersVC()
        vc.inputVideo = video
        vc.isFromSelectionVC = isFromSelectionVC
        return vc
    }

    // MARK: - Public vars

    public var inputVideo: YPMediaVideo!
    public var inputAsset: AVAsset { return AVAsset(url: inputVideo.url) }
    public var didSave: ((YPMediaItem) -> Void)?
    public var didCancel: (() -> Void)?

    // MARK: - Private vars

    private var playbackTimeCheckerTimer: Timer?
    private var imageGenerator: AVAssetImageGenerator?
    private var isFromSelectionVC = false
    private var wasPlaying = false

    private let trimmerContainerView: UIView = {
        let v = UIView()
        return v
    }()
    private let trimmerView: TrimmerView = {
        let v = TrimmerView()
        v.mainColor = YPConfig.colors.trimmerMainColor
        v.handleColor = YPConfig.colors.trimmerHandleColor
        v.positionBarColor = YPConfig.colors.positionLineColor
        v.maxDuration = YPConfig.video.trimmerMaxDuration
        v.minDuration = YPConfig.video.trimmerMinDuration
        return v
    }()
    private let coverThumbSelectorView: ThumbSelectorView = {
        let v = ThumbSelectorView()
        v.thumbBorderColor = YPConfig.colors.coverSelectorBorderColor
        v.isHidden = true
        return v
    }()
    private lazy var trimBottomItem: YPMenuItem = {
        let v = YPMenuItem()
        v.textLabel.text = YPConfig.wordings.trim
//        v.button.addTarget(self, action: #selector(selectTrim), for: .touchUpInside)
        v.isHidden = true
        return v
    }()
    private lazy var coverBottomItem: YPMenuItem = {
        let v = YPMenuItem()
        v.textLabel.text = YPConfig.wordings.cover
//        v.button.addTarget(self, action: #selector(selectCover), for: .touchUpInside)
        v.isHidden = true
        return v
    }()
    private let videoView: YPVideoView = {
        let v = YPVideoView()
        return v
    }()
    private let coverImageView: UIImageView = {
        let v = UIImageView()
        v.contentMode = .scaleAspectFit
        v.isHidden = true
        return v
    }()
    private var trimmer: VideoTrimmer = {
        let trimmer = VideoTrimmer()
        trimmer.minimumDuration = CMTime(seconds: YPConfig.video.trimmerMinDuration, preferredTimescale: 600)
        trimmer.maximumDuration = CMTime(seconds: YPConfig.video.trimmerMaxDuration, preferredTimescale: 600)
        ypLog("maximumDuration is \(YPConfig.video.trimmerMaxDuration), minimum is \(YPConfig.video.trimmerMinDuration)")
        trimmer.addTarget(self, action: #selector(didBeginTrimming(_:)), for: VideoTrimmer.didBeginTrimming)
        trimmer.addTarget(self, action: #selector(didEndTrimming(_:)), for: VideoTrimmer.didEndTrimming)
        trimmer.addTarget(self, action: #selector(selectedRangeDidChanged(_:)), for: VideoTrimmer.selectedRangeChanged)
        trimmer.addTarget(self, action: #selector(didBeginScrubbing(_:)), for: VideoTrimmer.didBeginScrubbing)
        trimmer.addTarget(self, action: #selector(didEndScrubbing(_:)), for: VideoTrimmer.didEndScrubbing)
        trimmer.addTarget(self, action: #selector(progressDidChanged(_:)), for: VideoTrimmer.progressChanged)
        return trimmer
    }()

    // MARK: - Live cycle

    override public func viewDidLoad() {
        super.viewDidLoad()

        setupLayout()
        title = YPConfig.wordings.trim
        view.backgroundColor = YPConfig.colors.filterBackgroundColor
        setupNavigationBar(isFromSelectionVC: self.isFromSelectionVC)

        // Remove the default and add a notification to repeat playback from the start
        videoView.removeReachEndObserver()
        NotificationCenter.default
            .addObserver(self,
                         selector: #selector(itemDidFinishPlaying(_:)),
                         name: .AVPlayerItemDidPlayToEndTime,
                         object: videoView.player.currentItem)
        
        // Set initial video cover
        imageGenerator = AVAssetImageGenerator(asset: self.inputAsset)
        imageGenerator?.appliesPreferredTrackTransform = true
        //didChangeThumbPosition(CMTime(seconds: 1, preferredTimescale: 1))
        
        trimmer.asset = inputAsset
        updatePlayerAsset()
    }

    override public func viewDidAppear(_ animated: Bool) {
        
        //OLD CODE
//        trimmerView.asset = inputAsset
//        trimmerView.delegate = self
        
        //NEW CODE - START
        videoView.player.addPeriodicTimeObserver(forInterval: CMTime(value: 1, timescale: 30), queue: .main) { [weak self] time in
            guard let self = self else {return}
            // when we're not trimming, the players starting point is actual later than the trimmer,
            // (because the vidoe has been trimmed), so we need to account for that.
            // When we're trimming, we always show the full video
            let finalTime = self.trimmer.trimmingState == .none ? CMTimeAdd(time, self.trimmer.selectedRange.start) : time
            self.trimmer.progress = finalTime
        }

        updateLabels()
        //NEW CODE - END
        
//        coverThumbSelectorView.asset = inputAsset
//        coverThumbSelectorView.delegate = self
//
//        selectTrim()
        videoView.loadVideo(inputVideo)
        videoView.showPlayImage(show: true)
        //startPlaybackTimeChecker()
        
        super.viewDidAppear(animated)
    }
    
    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

//        stopPlaybackTimeChecker()
        videoView.stop()
    }

    // MARK: - Setup

    private func setupNavigationBar(isFromSelectionVC: Bool) {
        if isFromSelectionVC {
            navigationItem.leftBarButtonItem = UIBarButtonItem(title: YPConfig.wordings.cancel,
                                                               style: .plain,
                                                               target: self,
                                                               action: #selector(cancel))
            navigationItem.leftBarButtonItem?.setFont(font: YPConfig.fonts.leftBarButtonFont, forState: .normal)
        }
        setupRightBarButtonItem()
    }

    private func setupRightBarButtonItem() {
        let rightBarButtonTitle = isFromSelectionVC ? YPConfig.wordings.done : YPConfig.wordings.next
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: rightBarButtonTitle,
                                                            style: .done,
                                                            target: self,
                                                            action: #selector(save))
        navigationItem.rightBarButtonItem?.tintColor = YPConfig.colors.tintColor
        navigationItem.rightBarButtonItem?.setFont(font: YPConfig.fonts.rightBarButtonFont, forState: .normal)
    }

    private func setupLayout() {
        view.subviews(
            trimBottomItem,
            coverBottomItem,
            videoView,
            coverImageView,
            trimmerContainerView.subviews(
//                trimmerView,
//                coverThumbSelectorView
                trimmer
            )
        )

        trimBottomItem.leading(0).height(40)
        trimBottomItem.Bottom == view.safeAreaLayoutGuide.Bottom
        trimBottomItem.Trailing == coverBottomItem.Leading
        coverBottomItem.Bottom == view.safeAreaLayoutGuide.Bottom
        coverBottomItem.trailing(0)
        equal(sizes: trimBottomItem, coverBottomItem)

        videoView.heightEqualsWidth().fillHorizontally().top(0)
        videoView.Bottom == trimmerContainerView.Top

        coverImageView.followEdges(videoView)

        trimmerContainerView.fillHorizontally()
        trimmerContainerView.Top == videoView.Bottom
        trimmerContainerView.Bottom == trimBottomItem.Top

//        trimmerView.fillHorizontally(padding: 30).centerVertically()
//        trimmerView.Height == trimmerContainerView.Height / 3
        
        trimmer.fillHorizontally(padding: 30).centerVertically()
        //trimmer.Height == trimmerContainerView.Height / 3
        trimmer.height(50.0)

        //coverThumbSelectorView.followEdges(trimmerView)
    }

    // MARK: - Actions

    @objc private func save() {
        guard let didSave = didSave else {
            return ypLog("Don't have saveCallback")
        }

        navigationItem.rightBarButtonItem = YPLoaders.defaultLoader

        do {
            let asset = AVURLAsset(url: inputVideo.url)
//            let trimmedAsset = try asset
//                .assetByTrimming(startTime: trimmerView.startTime ?? CMTime.zero,
//                                 endTime: trimmerView.endTime ?? inputAsset.duration)
            
            let trimmedAsset = try asset
                .assetByTrimming(startTime: trimmer.selectedRange.start,
                                 endTime: trimmer.selectedRange.end)
            
            // Looks like file:///private/var/mobile/Containers/Data/Application
            // /FAD486B4-784D-4397-B00C-AD0EFFB45F52/tmp/8A2B410A-BD34-4E3F-8CB5-A548A946C1F1.mov
            let destinationURL = URL(fileURLWithPath: NSTemporaryDirectory())
                .appendingUniquePathComponent(pathExtension: YPConfig.video.fileType.fileExtension)
            
            _ = trimmedAsset.export(to: destinationURL) { [weak self] session in
                switch session.status {
                case .completed:
                    DispatchQueue.main.async {
                        if let coverImage = self?.coverImageView.image {
                            let resultVideo = YPMediaVideo(thumbnail: coverImage,
														   videoURL: destinationURL,
														   asset: self?.inputVideo.asset)
                            didSave(YPMediaItem.video(v: resultVideo))
                            self?.setupRightBarButtonItem()
                        } else {
                            ypLog("Don't have coverImage.")
                        }
                    }
                case .failed:
                    ypLog("Export of the video failed. Reason: \(String(describing: session.error))")
                default:
                    ypLog("Export session completed with \(session.status) status. Not handled")
                }
            }
        } catch let error {
            ypLog("Error: \(error)")
        }
    }
    
    @objc private func cancel() {
        didCancel?()
    }

    // MARK: - Bottom buttons

//    @objc private func selectTrim() {
//        title = YPConfig.wordings.trim
//
//        trimBottomItem.select()
//        coverBottomItem.deselect()
//
//        trimmerView.isHidden = false
//        videoView.isHidden = false
//        coverImageView.isHidden = true
//        coverThumbSelectorView.isHidden = true
//    }
    
//    @objc private func selectCover() {
//        title = YPConfig.wordings.cover
//
//        trimBottomItem.deselect()
//        coverBottomItem.select()
//
//        trimmerView.isHidden = true
//        videoView.isHidden = true
//        coverImageView.isHidden = false
//        coverThumbSelectorView.isHidden = false
//
//        stopPlaybackTimeChecker()
//        videoView.stop()
//    }
    
    
    // MARK: - Input
    @objc private func didBeginTrimming(_ sender: VideoTrimmer) {
        updateLabels()

        wasPlaying = (videoView.player.timeControlStatus != .paused)
        videoView.player.pause()

        updatePlayerAsset()
    }

    @objc private func didEndTrimming(_ sender: VideoTrimmer) {
        updateLabels()

        if wasPlaying == true {
            videoView.player.play()
        }

        updatePlayerAsset()
    }

    @objc private func selectedRangeDidChanged(_ sender: VideoTrimmer) {
        updateLabels()
    }

    @objc private func didBeginScrubbing(_ sender: VideoTrimmer) {
        updateLabels()

        wasPlaying = (videoView.player.timeControlStatus != .paused)
        videoView.player.pause()
    }

    @objc private func didEndScrubbing(_ sender: VideoTrimmer) {
        updateLabels()

        if wasPlaying == true {
            videoView.player.play()
        }
    }

    @objc private func progressDidChanged(_ sender: VideoTrimmer) {
        updateLabels()

        let time = CMTimeSubtract(trimmer.progress, trimmer.selectedRange.start)
        videoView.player.seek(to: time, toleranceBefore: .zero, toleranceAfter: .zero)
    }
    
    // MARK: - Various Methods

    // Updates the bounds of the cover picker if the video is trimmed
    // TODO: Now the trimmer framework doesn't support an easy way to do this.
    // Need to rethink a flow or search other ways.
//    private func updateCoverPickerBounds() {
//        if let startTime = trimmerView.startTime,
//            let endTime = trimmerView.endTime {
//            if let selectedCoverTime = coverThumbSelectorView.selectedTime {
//                let range = CMTimeRange(start: startTime, end: endTime)
//                if !range.containsTime(selectedCoverTime) {
//                    // If the selected before cover range is not in new trimeed range,
//                    // than reset the cover to start time of the trimmed video
//                }
//            } else {
//                // If none cover time selected yet, than set the cover to the start time of the trimmed video
//            }
//        }
//    }
    
    //NEW CODE - START
    private func updateLabels() {
//        leadingTrimLabel.text = trimmer.selectedRange.start.displayString
//        currentTimeLabel.text = trimmer.progress.displayString
//        trailingTrimLabel.text = trimmer.selectedRange.end.displayString
        print("Start: \(trimmer.selectedRange.start.displayString)")
        print("current: \(trimmer.progress.displayString)")
        print("End: \(trimmer.selectedRange.end.displayString)")
    }

    private func updatePlayerAsset() {
//        let outputRange = trimmer.trimmingState == .none ? trimmer.selectedRange : asset.fullRange
//        let trimmedAsset = asset.trimmedComposition(outputRange)
//        if trimmedAsset != player.currentItem?.asset {
//            player.replaceCurrentItem(with: AVPlayerItem(asset: trimmedAsset))
//        }
        
        let outputRange = trimmer.trimmingState == .none ? trimmer.selectedRange : inputAsset.fullRange
        let trimmedAsset = inputAsset.trimmedComposition(outputRange)
        if trimmedAsset != videoView.player.currentItem?.asset {
            videoView.player.replaceCurrentItem(with: AVPlayerItem(asset: trimmedAsset))
        }
    }
    //NEW CODE - END
    
    // MARK: - Trimmer playback
    
    @objc private func itemDidFinishPlaying(_ notification: Notification) {
        //if let startTime = trimmerView.startTime {
            //videoView.player.seek(to: startTime)
        //}
        videoView.player.seek(to: trimmer.selectedRange.start)
    }
    
//    private func startPlaybackTimeChecker() {
//        stopPlaybackTimeChecker()
//        playbackTimeCheckerTimer = Timer
//            .scheduledTimer(timeInterval: 0.05, target: self,
//                            selector: #selector(onPlaybackTimeChecker),
//                            userInfo: nil,
//                            repeats: true)
//    }
    
//    private func stopPlaybackTimeChecker() {
//        playbackTimeCheckerTimer?.invalidate()
//        playbackTimeCheckerTimer = nil
//    }
    
//    @objc private func onPlaybackTimeChecker() {
//        guard let startTime = trimmerView.startTime,
//            let endTime = trimmerView.endTime else {
//            return
//        }
//
//        let playBackTime = videoView.player.currentTime()
//        trimmerView.seek(to: playBackTime)
//
//        if playBackTime >= endTime {
//            videoView.player.seek(to: startTime,
//                                  toleranceBefore: CMTime.zero,
//                                  toleranceAfter: CMTime.zero)
//            trimmerView.seek(to: startTime)
//        }
//    }
}

// MARK: - TrimmerViewDelegate
//extension YPVideoFiltersVC: TrimmerViewDelegate {
//    public func positionBarStoppedMoving(_ playerTime: CMTime) {
//        videoView.player.seek(to: playerTime, toleranceBefore: CMTime.zero, toleranceAfter: CMTime.zero)
//        videoView.play()
//        startPlaybackTimeChecker()
//        updateCoverPickerBounds()
//    }
//
//    public func didChangePositionBar(_ playerTime: CMTime) {
//        stopPlaybackTimeChecker()
//        videoView.pause()
//        videoView.player.seek(to: playerTime, toleranceBefore: CMTime.zero, toleranceAfter: CMTime.zero)
//    }
//}

// MARK: - ThumbSelectorViewDelegate
extension YPVideoFiltersVC: ThumbSelectorViewDelegate {
    public func didChangeThumbPosition(_ imageTime: CMTime) {
        if let imageGenerator = imageGenerator,
            let imageRef = try? imageGenerator.copyCGImage(at: imageTime, actualTime: nil) {
            coverImageView.image = UIImage(cgImage: imageRef)
        }
    }
}
