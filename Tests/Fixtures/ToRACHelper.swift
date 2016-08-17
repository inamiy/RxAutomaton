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
    func delay(time: NSTimeInterval, onScheduler scheduler: SchedulerType) -> Observable<E> {
        return self.flatMap { element in
            return Observable<Int>.interval(time, scheduler: scheduler)
                .map { _ in element }
                .take(1)
        }
    }
}

extension ObservableType {
    final func observeNext(next: E -> Void) -> Disposable {
        return self.subscribeNext(next)
    }

    final func observe(observer: Event<E> -> Void) -> Disposable {
        return self.subscribe(AnyObserver(eventHandler: observer))
    }
}

extension ObserverType {
    final func sendNext(value: E) {
        self.onNext(value)
    }

    final func sendCompleted() {
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
    func advanceByInterval(interval: NSTimeInterval) {
        self.advanceTo(NSDate(timeInterval: interval, sinceDate: self.clock))
    }
}
