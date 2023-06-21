//
//  VideoFiltersVC.swift
//  YPImagePicker
//
//  Created by Nik Kov || nik-kov.com on 18.04.2018.
//  Copyright © 2018 Yummypets. All rights reserved.
//

import UIKit
import Photos
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
    private let videoView: YPVideoView = {
        let v = YPVideoView()
        return v
    }()
    private lazy var trimmer: VideoTrimmer = {
        let trimmer = VideoTrimmer()
        trimmer.minimumDuration = CMTime(seconds: YPConfig.video.trimmerMinDuration, preferredTimescale: 600)
        trimmer.maximumDuration = CMTime(seconds: YPConfig.video.trimmerMaxDuration, preferredTimescale: 600)
        trimmer.addTarget(self, action: #selector(didBeginTrimming(_:)), for: VideoTrimmer.didBeginTrimming)
        trimmer.addTarget(self, action: #selector(didEndTrimming(_:)), for: VideoTrimmer.didEndTrimming)
        trimmer.addTarget(self, action: #selector(selectedStartRangeDidChanged(_:)), for: VideoTrimmer.selectedStartRangeChanged)
        trimmer.addTarget(self, action: #selector(selectedEndRangeDidChanged(_:)), for: VideoTrimmer.selectedEndRangeChanged)
        trimmer.addTarget(self, action: #selector(didBeginScrubbing(_:)), for: VideoTrimmer.didBeginScrubbing)
        trimmer.addTarget(self, action: #selector(didEndScrubbing(_:)), for: VideoTrimmer.didEndScrubbing)
        trimmer.addTarget(self, action: #selector(progressDidChanged(_:)), for: VideoTrimmer.progressChanged)
        return trimmer
    }()
    private let lblVideoTimeRange: UILabel = {
        let v = UILabel()
        v.textColor = .ypLabel
        v.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        v.alpha = 0.0
        return v
    }()
    private let lblVideoLength: UILabel = {
        let v = UILabel()
        v.textColor = .white
        v.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        v.text = "00:00"
        v.setContentCompressionResistancePriority(.required, for: .horizontal)
        v.setContentCompressionResistancePriority(.required, for: .vertical)
        return v
    }()
    private let videoLengthView: UIView = {
        let v = UIView()
        v.backgroundColor = .black
        v.clipsToBounds = true
        v.layer.cornerRadius = 10
        v.setContentHuggingPriority(.defaultLow, for: .horizontal)
        return v
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
        
        trimmer.asset = inputAsset
        updatePlayerAsset()
    }

    override public func viewDidAppear(_ animated: Bool) {
        videoView.loadVideo(inputVideo)
        videoView.showPlayImage(show: true)
        
        videoView.player.addPeriodicTimeObserver(forInterval: CMTime(value: 1, timescale: 30), queue: .main) { [weak self] time in
            guard let self = self else { return }
            // when we're not trimming, the players starting point is actual later than the trimmer,
            // (because the vidoe has been trimmed), so we need to account for that.
            // When we're trimming, we always show the full video
            ypLog("trimmingState \(self.trimmer.trimmingState)")
            ypLog("time \(CMTimeGetSeconds(time))")
            ypLog("Start \(CMTimeGetSeconds(self.trimmer.selectedRange.start))")
            let finalTime = self.trimmer.trimmingState == .none ? CMTimeAdd(time, self.trimmer.selectedRange.start) : time
            ypLog(" addPeriodicTimeObserver trimmer progress is: \(CMTimeGetSeconds(finalTime))")
            print("======================================================")
            self.trimmer.progress = finalTime
        }

        updateLabels()
        super.viewDidAppear(animated)
    }
    
    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
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
            videoView,
            trimmerContainerView.subviews(
                lblVideoTimeRange,
                trimmer,
                videoLengthView.subviews(
                    lblVideoLength
                )
            )
        )

        videoView.heightEqualsWidth().fillHorizontally().top(0)
        videoView.Bottom == trimmerContainerView.Top
        trimmerContainerView.fillHorizontally()
        trimmerContainerView.Top == videoView.Bottom
        trimmerContainerView.Bottom == view.safeAreaLayoutGuide.Bottom - 40
        trimmer.fillHorizontally(padding: 16).centerVertically()
        trimmer.height(50.0)
        lblVideoTimeRange.Bottom == trimmer.Top - 20
        lblVideoTimeRange.centerHorizontally()
        videoLengthView.centerHorizontally()
        videoLengthView.height(40)
        videoLengthView.Top == trimmer.Bottom + 20
        lblVideoLength.fillContainer(padding: 4)
    }

    // MARK: - Actions
    @objc private func save() {
        guard let didSave = didSave else {
            return ypLog("Don't have saveCallback")
        }

        navigationItem.rightBarButtonItem = YPLoaders.defaultLoader

        do {
            let asset = AVURLAsset(url: inputVideo.url)
            
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
                            let coverImage = imageFromBundle("yp_empty")
                            let resultVideo = YPMediaVideo(thumbnail: coverImage,
														   videoURL: destinationURL,
														   asset: self?.inputVideo.asset)
                            didSave(YPMediaItem.video(v: resultVideo))
                            self?.setupRightBarButtonItem()
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
    
    
    // MARK: - Input
    @objc private func didBeginTrimming(_ sender: VideoTrimmer) {
        updateLabels()

        wasPlaying = (videoView.player.timeControlStatus != .paused)
        videoView.player.pause()

        updatePlayerAsset()
    }

    @objc private func didEndTrimming(_ sender: VideoTrimmer) {
        updateLabels()
        
        if lblVideoTimeRange.alpha > 0 {
            UIView.animate(withDuration: 0.2, delay: 0.0, options: [.curveEaseOut]) {
                self.lblVideoTimeRange.alpha = 0
            }
        }

        updatePlayerAsset()
    }

    @objc private func selectedStartRangeDidChanged(_ sender: VideoTrimmer) {
        updateLabels()
        updateTrimmerRange()
        videoView.player.seek(to: trimmer.selectedRange.start, toleranceBefore: .zero, toleranceAfter: .zero)
    }
    
    @objc private func selectedEndRangeDidChanged(_ sender: VideoTrimmer) {
        updateLabels()
        updateTrimmerRange()
        videoView.player.seek(to: trimmer.selectedRange.end, toleranceBefore: .zero, toleranceAfter: .zero)
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
        ypLog("progressDidChanged progress: \(CMTimeGetSeconds(trimmer.progress))")
        ypLog("progressDidChanged time: \(CMTimeGetSeconds(time))")
        videoView.player.seek(to: time, toleranceBefore: .zero, toleranceAfter: .zero)
    }
    
    private func updateLabels() {
        if trimmer.selectedRange != .invalid && trimmer.selectedRange != .zero {
            let duration = CMTimeSubtract(trimmer.selectedRange.end, trimmer.selectedRange.start)
            lblVideoLength.text = "\(duration.displayString)"
        }
       
        lblVideoTimeRange.text = "\(trimmer.selectedRange.start.displayString) - \(trimmer.selectedRange.end.displayString)"
    }

    private func updatePlayerAsset() {
        let outputRange = trimmer.trimmingState == .none ? trimmer.selectedRange : inputAsset.fullRange
        let trimmedAsset = inputAsset.trimmedComposition(outputRange)
        if trimmedAsset != videoView.player.currentItem?.asset {
            videoView.player.replaceCurrentItem(with: AVPlayerItem(asset: trimmedAsset))
        }
        ypLog("updatePlayerAsset called")
    }
    
    private func updateTrimmerRange() {
        if lblVideoTimeRange.alpha == 0 {
            UIView.animate(withDuration: 0.2, delay: 0.0, options: [.curveEaseOut]) {
                self.lblVideoTimeRange.alpha = 1
            }
        }
    }
    
    // MARK: - Trimmer playback
    
    @objc private func itemDidFinishPlaying(_ notification: Notification) {
        videoView.player.seek(to: trimmer.selectedRange.start)
    }
}
