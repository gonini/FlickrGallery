//
//  TicketOfficeVC.swift
//  FlickrGallery
//
//  Created by 장공의 on 26/03/2019.
//  Copyright © 2019 gonini. All rights reserved.
//

import UIKit

import GalleryDomain
import ReactorKit
import RxSwift
import RxCocoa

class TicketOfficeVC: UIViewController, StoryboardView {
    var disposeBag = DisposeBag()
    var lazyGalleryVC: GalleryVCLazyHolder?
    
    @IBOutlet weak var viewingTimeSlider: UISlider!
    @IBOutlet weak var enterGalleryButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    func bind(reactor: TicketOfficeReactor) {
        reactor.state.map { $0.viewingTimeLimit }
            .distinctUntilChanged()
            .map { (Float($0.minTime), Float($0.maxTime)) }
            .bind(onNext: { [weak self] in
                guard let `self` = self else { return }
                
                self.viewingTimeSlider.minimumValue = $0.0
                self.viewingTimeSlider.maximumValue = $0.1
            })
            .disposed(by: disposeBag)
        
        reactor.state.map { $0.viewingTime }
            .distinctUntilChanged()
            .map { Int(exactly: $0)! }
            .map { "작품 당 \($0)초 감상 티켓으로 입장" }
            .bind(onNext: { [weak self] in
                guard let `self` = self else { return }
                
                self.enterGalleryButton.setTitle($0, for: .normal)
            })
            .disposed(by: disposeBag)
    
        viewingTimeSlider.rx.timeValue
            .debounce(0.3, scheduler: MainScheduler.instance)
            .map(Reactor.Action.selectTickets)
            .bind(to: reactor.action)
        .disposed(by: disposeBag)
        
        enterGalleryButton.rx.tap
            .debounce(0.3, scheduler: MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                guard let `self` = self,
                    let galleryVC = self.lazyGalleryVC?.galleryVC.instance else { return }
                
                self.navigationController?.pushViewController(galleryVC, animated: true)
            }).disposed(by: disposeBag)
    }
}

extension Reactive where Base: UISlider {
    var timeValue: ControlEvent<TimeInterval> {
        let source = base.rx.value.map { TimeInterval(exactly: round($0))! }
        return ControlEvent(events: source)
    }
}
