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
        reactor.state.map { $0.artImage }
            .flatMap { Observable.from(optional: $0) }
            .distinctUntilChanged()
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] url in
                guard let `self` = self else { return }
                print(url)
                self.artImageView.load(url: url)
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
            .throttle(0.3, scheduler: MainScheduler.instance)
        
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
    func load(url: URL) {
        DispatchQueue.global().async { [weak self] in
            if let data = try? Data(contentsOf: url) {
                if let image = UIImage(data: data) {
                    DispatchQueue.main.async {
                        self?.image = image
                    }
                }
            }
        }
    }
}
