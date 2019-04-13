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

final class GalleryVC: UIViewController, StoryboardView, ViewingTimeSlider {
    var disposeBag = DisposeBag()
    
    @IBOutlet var viewingTimeSlider: UISlider!
    @IBOutlet var viewingTimeLabel: UILabel!
    @IBOutlet var artImageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    func bind(reactor: GalleryReactor) {
        rx.viewDidAppear
            .map { _ in Reactor.Action.appearScreen }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        rx.viewDidDisappear
            .map { _ in Reactor.Action.disAppearScreen }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        reactor.state.map { $0.galleyImage }
            .distinctUntilChanged { $0 == $1 }
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] in
                guard let `self` = self,
                    let image = $0.image else { return }
                self.artImageView.load(data: image, duration: $0.imswpAnmtnTime)
            }).disposed(by: disposeBag)
        
        bindRange(rangeStream: reactor.state
            .map { $0.viewingTimeLimit })
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
