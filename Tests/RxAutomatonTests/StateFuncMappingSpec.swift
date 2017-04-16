//
//  StateFuncMappingSpec.swift
//  RxAutomaton
//
//  Created by Yasuhiro Inami on 2016-11-26.
//  Copyright © 2016 Yasuhiro Inami. All rights reserved.
//

import RxSwift
import RxTest
import RxAutomaton
import Quick
import Nimble

/// Tests for state-change function mapping.
class StateFuncMappingSpec: QuickSpec
{
    override func spec()
    {
        describe("State-change function mapping") {

            typealias Automaton = RxAutomaton.Automaton<CountState, CountInput>
            typealias EffectMapping = Automaton.EffectMapping

            let (signal, observer) = Observable<CountInput>.pipe()
            var automaton: Automaton?

            beforeEach {
                let mappings: [Automaton.EffectMapping] = [
                    .increment | { $0 + 1 } | .empty(),
                    .decrement | { $0 - 1 } | .empty(),
                    ]

                // strategy = `.merge`
                automaton = Automaton(state: 0, input: signal, mapping: reduce(mappings), strategy: .merge)
            }

            it("`.increment` and `.decrement` succeed") {
                expect(automaton?.state.value) == 0
                observer.send(next: .increment)
                expect(automaton?.state.value) == 1
                observer.send(next: .increment)
                expect(automaton?.state.value) == 2
                observer.send(next: .decrement)
                expect(automaton?.state.value) == 1
                observer.send(next: .decrement)
                expect(automaton?.state.value) == 0
            }

        }
    }
}
