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
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    func bind(reactor: GalleryReactor) {
        reactor.state.map { $0.viewingTimeLimit }
            .distinctUntilChanged()
            .map { (Float($0.minTime), Float($0.maxTime)) }
            .bind(onNext: { [weak self] in
                guard let `self` = self else { return }
                
                self.viewingTimeSlider.minimumValue = $0.0
                self.viewingTimeSlider.maximumValue = $0.1
            })
            .disposed(by: disposeBag)
        
        let propagetedViewingTime = reactor.state.map { $0.propagetedViewingTime }
            .distinctUntilChanged()
        
        propagetedViewingTime
            .bind(onNext: { [weak self] in
                guard let `self` = self else { return }
                self.viewingTimeSlider.value = Float($0)
            })
            .disposed(by: disposeBag)
        
        let viewingTime = viewingTimeSlider.rx.timeValue
            .debounce(0.3, scheduler: MainScheduler.instance)
        
        viewingTime.map(Reactor.Action.exchangeTickets)
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        viewingTime.map { "현재 감상 시간 \(Int($0))초" }
            .subscribe { [weak self] in
                guard let `self` = self, let title = $0.element else { return }
                self.viewingTimeLabel.text = title
            }.disposed(by: disposeBag)    
    }
}
