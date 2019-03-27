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
    
    @IBOutlet weak var viewingTimeSlider: UISlider!
    @IBOutlet weak var enterGalleryButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    func bind(reactor: GalleryTicketReactor) {
        reactor.action.on(Event.next(Reactor.Action.enterTicketOffice))
        
        reactor.state.map { $0.viewingTimeLimit }
            .map { (Float($0.minTime), Float($0.maxTime)) }
            .bind(onNext: { [weak self] in
                guard let `self` = self else { return }
                self.viewingTimeSlider.minimumValue = $0.0
                self.viewingTimeSlider.maximumValue = $0.1
            })
            .disposed(by: disposeBag)
        
        reactor.state.map { $0.viewingTime }
            .map { Int(exactly: $0)! }
            .map { "작품 당 \($0)초 감상 티켓으로 입장" }
            .bind(onNext: { [weak self] in
                guard let `self` = self else { return }
                self.enterGalleryButton.setTitle($0, for: .normal)
            })
            .disposed(by: disposeBag)
        
        viewingTimeSlider.rx.value
            .debounce(0.3, scheduler: MainScheduler.instance)
            .map { TimeInterval(exactly: round($0))! }
            .map(Reactor.Action.selectTickets)
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
    }
}
