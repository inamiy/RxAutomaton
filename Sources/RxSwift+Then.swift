//
//  RxSwift+Then.swift
//  RxAutomaton
//
//  Created by Yasuhiro Inami on 2016-08-15.
//  Copyright © 2016 Yasuhiro Inami. All rights reserved.
//

import RxSwift

extension ObservableType {

    /// From ReactiveCocoa (naive implementation).
    @warn_unused_result(message="http://git.io/rxs.uo")
    public func then<E2, O: ObservableConvertibleType where O.E == E2>(second: O) -> Observable<E2> {
        return self
            .filter { _ in false }
            .flatMap { _ in Observable<E2>.empty() }
            .concat(second)
    }

    @warn_unused_result(message="http://git.io/rxs.uo")
    public func then<E2>(value value: E2) -> Observable<E2> {
        return self.then(Observable.just(value))
    }

}
