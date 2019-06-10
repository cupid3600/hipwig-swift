//
//  PlayVideoServiceImplementation.swift
//  HipWig
//
//  Created by Vladyslav Shepitko on 2/8/19.
//  Copyright © 2019 HipWig. All rights reserved.
//

import UIKit
import AVFoundation

protocol VideoCell: class {
    var user: User? { get set }
    var contentView: UIView { get }
    
    func playVideo()
    func stopVideo()
    var reuseAction: () -> Void { get set }
    var stopPlayingAction: () -> Void { get set }
}

protocol PlayVideoServiceDelegate: class {
    var displayingVideoCells: [VideoCell] { get }
    var workFrame: CGRect { get }
}

protocol PlayVideoService: class, UIScrollViewDelegate {
    var shouldPlay: Bool { get set }
    
    func setup(delegate: PlayVideoServiceDelegate)
    func startSession()
    func pauseSession()
    func recreateSession()
}

private enum CellState: Int {
    case playing
    case paused
}

private class CellWrapper {
    
    var state: CellState = .paused
    var cell: VideoCell
    
    init(_ cell: VideoCell) {
        self.cell = cell
    }
}

class PlayVideoServiceImplementation: NSObject {
    
    weak var delegate: PlayVideoServiceDelegate?
    
    var shouldPlay: Bool = false {
        didSet {
            if shouldPlay {
                self.startSession()
            } else {
                self.pauseSession()
            }
        }
    }
    
    fileprivate var deceleratingOffset: CGFloat = 0.0
    fileprivate var dragingOffset: CGFloat = 0.0
    
    private var coordinator: [CellWrapper] = []
    private let maxCellsToPlay = 2
    private let deltaOffset: CGFloat = 0.5
    private var requestManager: RequestsManager = RequestsManager.manager
    
    override init() {
        super.init()
    } 

    private func playRandomVideo(unavailableCells playingCells: [VideoCell]) {
        DispatchQueue.main.async {
            self.nextPlayingCell(matched: playingCells) { availableCell in
                guard let cell = availableCell else {
                    return
                }
                
                if self.coordinator.count >= self.maxCellsToPlay {
                    return
                }
                
                let container = CellWrapper(cell)
                self.coordinator.append(container)
                
                let reuseAction = { [weak self, weak container] in
                    guard let `self` = self else { return }
                    guard let container = container else { return }
                    
                    self.stopPlaying(container)
                    self.playRandomCell()
                }
                
                cell.stopPlayingAction = reuseAction
                cell.reuseAction = reuseAction
                
                cell.playVideo()
                container.state = .playing
            }
        }
    }
    
    private func stopPlaying(_ container: CellWrapper) {
        container.state = .paused
        container.cell.stopVideo()
        
        self.coordinator = self.coordinator.filter{ $0.state != .paused }
    }
    
    private func playRandomCell() {
        let cells = self.coordinator.map{ $0.cell }
        self.playRandomVideo(unavailableCells: cells)
    }

    private func nextPlayingCell(matched unavailableCells: [VideoCell?], completion: (VideoCell?) -> Void) {
        guard let delegate = self.delegate else {
            completion(nil)
            return
        }
        
        let displayingVideoCells = delegate.displayingVideoCells
        let cells = displayingVideoCells.filter { cell in

            let cellRect = cell.contentView.convert(cell.contentView.bounds, to: UIScreen.main.coordinateSpace)
            let isAvailable = !unavailableCells.contains(where: { $0 === cell })

            return delegate.workFrame.intersects(cellRect) && isAvailable
        }

        let randomElement = cells.randomElement()
        completion(randomElement)
    }
    
    private func recalculatePlayingData() {
        guard let randomElement = coordinator.randomElement() else {
            return
        }
        
        self.stopPlaying(randomElement)
        
        self.playRandomCell()
    }
}

//MARK: - PlayVideoService
extension PlayVideoServiceImplementation : PlayVideoService {
    
    func recreateSession() {
        if self.shouldPlay {
            DispatchQueue.global(qos: .userInteractive).async { [weak self] in
                guard let `self` = self else { return }
            
                let cells = self.coordinator.map{ $0.cell }
                self.playRandomVideo(unavailableCells: cells)
            }
        }
    }
    
    func pauseSession() {
        for container in self.coordinator {
            self.stopPlaying(container)
        } 
    }
    
    func startSession() {
        if self.shouldPlay {
            DispatchQueue.global(qos: .userInteractive).async { [weak self] in
                guard let `self` = self else { return }
                
                self.pauseSession()
            
                for _ in 0 ..< self.maxCellsToPlay {
                    self.playRandomCell()
                }
            }
        }
    }
    
    func setup(delegate: PlayVideoServiceDelegate) {
        self.delegate = delegate
    }
}

extension PlayVideoServiceImplementation {
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        if self.shouldPlay {
            self.dragingOffset = abs(scrollView.contentOffset.y)
        }
    }
    
    func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView) {
        if self.shouldPlay {
            self.deceleratingOffset = abs(scrollView.contentOffset.y)
        }
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        if self.shouldPlay {
            let offset = abs((abs(scrollView.contentOffset.y) - deceleratingOffset) / UIScreen.main.bounds.height)

            if offset >= 0.1 {
                DispatchQueue.global(qos: .userInteractive).async { [weak self] in
                    guard let `self` = self else { return }
                    
                    self.recalculatePlayingData()
                }
            }
        }
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if self.shouldPlay {
            let offset = abs((abs(scrollView.contentOffset.y) - dragingOffset) / UIScreen.main.bounds.height)

            if decelerate == false && offset >= deltaOffset {
                DispatchQueue.global(qos: .userInteractive).async { [weak self] in
                    guard let `self` = self else { return }
                    
                    self.recalculatePlayingData()
                }
            }
        }
    }
}
