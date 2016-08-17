//
//  RxSwift+Pipe.swift
//  RxAutomaton
//
//  Created by Yasuhiro Inami on 2016-08-15.
//  Copyright © 2016 Yasuhiro Inami. All rights reserved.
//

import RxSwift

extension ObservableType {

    /// From ReactiveCocoa.
    public static func pipe() -> (Observable<E>, AnyObserver<E>) {
        let p = PublishSubject<E>()
        return (p.asObservable(), AnyObserver(eventHandler: p.asObserver().on))
    }

}
