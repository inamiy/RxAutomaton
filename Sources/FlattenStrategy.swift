//
//  FlattenStrategy.swift
//  RxAutomaton
//
//  Created by Yasuhiro Inami on 2016-08-15.
//  Copyright © 2016 Yasuhiro Inami. All rights reserved.
//

/// From ReactiveCocoa.
public enum FlattenStrategy: Equatable {
    /// The producers should be merged, so that any value received on any of the
    /// input producers will be forwarded immediately to the output producer.
    ///
    /// The resulting producer will complete only when all inputs have completed.
    case merge

    /// The producers should be concatenated, so that their values are sent in the
    /// order of the producers themselves.
    ///
    /// The resulting producer will complete only when all inputs have completed.
//    case concat   // TODO: implement `flatMapConcat`

    /// Only the events from the latest input producer should be considered for
    /// the output. Any producers received before that point will be disposed of.
    ///
    /// The resulting producer will complete only when the producer-of-producers and
    /// the latest producer has completed.
    case latest
}
