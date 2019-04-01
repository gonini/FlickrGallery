//
//  GalleryVC.swift
//  FlickrGallery
//
//  Created by 장공의 on 28/03/2019.
//  Copyright © 2019 gonini. All rights reserved.
//

import UIKit

import ReactorKit
import RxSwift
import GalleryDomain

final class GalleryVC: UIViewController, StoryboardView {
    var disposeBag = DisposeBag()
    
    @IBOutlet weak var viewingTimeSlider: UISlider!
    @IBOutlet weak var viewingTimeLabel: UILabel!
    @IBOutlet weak var artImageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    func bind(reactor: GalleryReactor) {
        reactor.state.map { $0.galleyImage }
            .distinctUntilChanged { $0 == $1 }
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] in
                guard let `self` = self,
                    let image = $0.image else { return }
                self.artImageView.load(data: image, duration: $0.imswpAnmtnTime)
            }).disposed(by: disposeBag)
        
        reactor.state.map { $0.viewingTimeLimit }
            .distinctUntilChanged()
            .map { (Float($0.minTime), Float($0.maxTime)) }
            .observeOn(MainScheduler.instance)
            .bind(onNext: { [weak self] in
                guard let `self` = self else { return }
                self.viewingTimeSlider.minimumValue = $0.0
                self.viewingTimeSlider.maximumValue = $0.1
            })
            .disposed(by: disposeBag)
        
        let propagetedViewingTime = reactor.state
            .map { $0.propagetedViewingTime }
            .flatMap { Observable.from(optional: $0) }
            .distinctUntilChanged()
            .observeOn(MainScheduler.instance)
        
        let viewingTime = viewingTimeSlider.rx
            .timeValue
            .debounce(0.5, scheduler: MainScheduler.instance)
            .skip(1)
        
        propagetedViewingTime
            .bind(onNext: { [weak self] in
                guard let `self` = self else { return }
                self.viewingTimeSlider.value = Float($0)
            })
            .disposed(by: disposeBag)
        
        viewingTime
            .map(Reactor.Action.exchangeTickets)
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        Observable.merge(propagetedViewingTime, viewingTime)
            .map { "현재 감상 시간 \(Int($0))초" }
            .observeOn(MainScheduler.instance)
            .subscribe { [weak self] in
                guard let `self` = self, let title = $0.element else { return }
                self.viewingTimeLabel.text = title
            }.disposed(by: disposeBag)    
    }
}

extension UIImageView {
    func load(data: Data, duration: TimeInterval) {
        DispatchQueue.global().async {
            guard let image = UIImage(data: data) else { return  }
            DispatchQueue.main.async { [weak self] in
                guard let `self` = self else { return }
                self.fadeOut(duration) { _ in
                    self.image = image
                    self.fadeIn(duration)
                }
            }
        }
    }
    
    // https://stackoverflow.com/questions/28288476/fade-in-and-fade-out-in-animation-swift
    func fadeIn(_ duration: TimeInterval = 0.5,
                delay: TimeInterval = 0.0,
                completion: @escaping ((Bool) -> Void) = {(finished: Bool) -> Void in}) {
        UIView.animate(withDuration: duration, delay: delay, options: UIView.AnimationOptions.curveEaseIn, animations: {
            self.alpha = 1.0
        }, completion: completion)  }
    
    func fadeOut(_ duration: TimeInterval = 0.5,
                 delay: TimeInterval = 0.0,
                 completion: @escaping (Bool) -> Void = {(finished: Bool) -> Void in}) {
        UIView.animate(withDuration: duration, delay: delay, options: UIView.AnimationOptions.curveEaseIn, animations: {
            self.alpha = 0.0
        }, completion: completion)
    }
        
}
