//
//  TicketOfficeVC.swift
//  FlickrGallery
//
//  Created by 장공의 on 26/03/2019.
//  Copyright © 2019 gonini. All rights reserved.
//

import UIKit

import GalleryDomain
import RxViewController
import RxSwift
import RxCocoa
import ReactorKit

class TicketOfficeVC: UIViewController, StoryboardView {
    var disposeBag = DisposeBag()
    var lazyGalleryVC: GalleryVCLazyHolder?
    
    @IBOutlet weak var viewingTimeSlider: UISlider!
    @IBOutlet weak var enterGalleryButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    func bind(reactor: TicketOfficeReactor) {
        reactor.state.map { $0.connectionStatus }
            .filter { !$0 }
            .observeOn(MainScheduler.instance)
            .subscribe { [weak self] _ in
                guard let `self` = self else { return }
               self.showConnectionFailureAlert()
            }
            .disposed(by: disposeBag)
        
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
            .distinctUntilChanged()
            .observeOn(MainScheduler.instance)
        
        propagetedViewingTime
            .bind(onNext: { [weak self] in
                guard let `self` = self else { return }
                self.viewingTimeSlider.value = Float($0)
            })
            .disposed(by: disposeBag)
        
        // Action
        let viewingTime = viewingTimeSlider.rx.timeValue
            .debounce(0.3, scheduler: MainScheduler.instance)
    
        viewingTime
            .map(Reactor.Action.selectTickets)
            .bind(to: reactor.action)
        .disposed(by: disposeBag)
        
        Observable<ViewingTime>.merge(viewingTime, propagetedViewingTime)
            .map { "작품 당 \(Int($0))초 감상 티켓으로 입장" }
            .subscribe { [weak self] in
                guard let `self` = self, let title = $0.element else { return }
                self.enterGalleryButton.setTitle(title, for: .normal)
        }.disposed(by: disposeBag)
        
        let galleryButtonTap = enterGalleryButton.rx.tap
            .debounce(0.3, scheduler: MainScheduler.instance)
        
        galleryButtonTap
            .map { Reactor.Action.useTickets }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        galleryButtonTap
            .subscribe(onNext: { [weak self] _ in
                guard let `self` = self, let galleryVC = self.lazyGalleryVC?.galleryVC.instance else { return }
                self.navigationController?.pushViewController(galleryVC, animated: true)
            })
            .disposed(by: disposeBag)
    }
    
    private func showConnectionFailureAlert() {
        let alertController = UIAlertController(title: "네트워크가 불안정합니다.", message:
            "잠시 후 다시 시도해주세요.", preferredStyle: .alert)
        alertController.addAction(.init(title: "종료하기", style: .cancel, handler: { _ in
            exit(0)
        }))
        self.present(alertController, animated: true)
    }
}

extension Reactive where Base: UISlider {
    var timeValue: ControlEvent<ViewingTime> {
        let source = base.rx.value.map { ViewingTime(exactly: round($0))! }
        return ControlEvent(events: source)
    }
}
