//
//  ToRACHelper.swift
//  RxAutomaton
//
//  Created by Yasuhiro Inami on 2016-08-15.
//  Copyright © 2016 Yasuhiro Inami. All rights reserved.
//

import Foundation
import RxSwift

// R-A-C! R-A-C!

extension ObservableType {
    func delay(_ time: DispatchTimeInterval, onScheduler scheduler: SchedulerType) -> Observable<Element> {
        return self.flatMap { element in
            return Observable<Int>.interval(time, scheduler: scheduler)
                .map { _ in element }
                .take(1)
        }
    }
}

extension ObservableType {
    @discardableResult
    func observeValues(_ next: @escaping (Element) -> Void) -> Disposable {
        return self.subscribe(onNext: next)
    }

    @discardableResult
    func observe(_ observer: @escaping (Event<Element>) -> Void) -> Disposable {
        return self.subscribe(AnyObserver(eventHandler: observer))
    }
}

extension ObserverType {
    func send(next value: Element) {
        self.onNext(value)
    }

    func sendCompleted() {
        self.onCompleted()
    }
}

extension Event {
    var isTerminating: Bool {
        return self.isStopEvent
    }
}

typealias TestScheduler = HistoricalScheduler

extension HistoricalScheduler {
    func advanceByInterval(_ interval: TimeInterval) {
        self.advanceTo(Date(timeInterval: interval, since: self.clock))
    }
}
