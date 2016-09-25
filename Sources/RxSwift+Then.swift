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
    public func then<E2, O: ObservableConvertibleType>(_ second: O) -> Observable<E2>
        where O.E == E2
    {
        return self
            .filter { _ in false }
            .flatMap { _ in Observable<E2>.empty() }
            .concat(second)
    }

    public func then<E2>(value: E2) -> Observable<E2> {
        return self.then(Observable.just(value))
    }

}
