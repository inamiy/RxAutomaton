//
//  StrategyLatestSpec.swift
//  RxAutomaton
//
//  Created by Yasuhiro Inami on 2016-08-15.
//  Copyright © 2016 Yasuhiro Inami. All rights reserved.
//

import RxSwift
import RxAutomaton
import Quick
import Nimble

/// EffectMapping tests with `strategy = .latest`.
class EffectMappingLatestSpec: QuickSpec
{
    override func spec()
    {
        typealias Automaton = RxAutomaton.Automaton<AuthState, AuthInput>
        typealias EffectMapping = Automaton.EffectMapping

        let (signal, observer) = Observable<AuthInput>.pipe()
        var automaton: Automaton?
        var lastReply: Reply<AuthState, AuthInput>?

        describe("strategy = `.latest`") {

            var testScheduler: TestScheduler!

            beforeEach {
                testScheduler = TestScheduler()

                /// Sends `.loginOK` after delay, simulating async work during `.loggingIn`.
                let loginOKProducer =
                    Observable.just(AuthInput.loginOK)
                    .delay(.seconds(1), onScheduler: testScheduler)

                /// Sends `.logoutOK` after delay, simulating async work during `.loggingOut`.
                let logoutOKProducer =
                    Observable.just(AuthInput.logoutOK)
                    .delay(.seconds(1), onScheduler: testScheduler)

                let mappings: [Automaton.EffectMapping] = [
                    .login    | .loggedOut  => .loggingIn  | loginOKProducer,
                    .loginOK  | .loggingIn  => .loggedIn   | .empty(),
                    .logout   | .loggedIn   => .loggingOut | logoutOKProducer,
                    .logoutOK | .loggingOut => .loggedOut  | .empty(),
                ]

                // strategy = `.latest`
                automaton = Automaton(state: .loggedOut, input: signal, mapping: reduce(mappings), strategy: .latest)

                automaton?.replies.observeValues { reply in
                    lastReply = reply
                }

                lastReply = nil
            }

            it("`strategy = .latest` should not interrupt inner effects when transition fails") {
                expect(automaton?.state.value) == .loggedOut
                expect(lastReply).to(beNil())

                observer.send(next: .login)

                expect(lastReply?.input) == .login
                expect(lastReply?.fromState) == .loggedOut
                expect(lastReply?.toState) == .loggingIn
                expect(automaton?.state.value) == .loggingIn

                testScheduler.advanceByInterval(0.1)

                // fails (`loginOKProducer` will not be interrupted)
                observer.send(next: .login)

                expect(lastReply?.input) == .login
                expect(lastReply?.fromState) == .loggingIn
                expect(lastReply?.toState).to(beNil())
                expect(automaton?.state.value) == .loggingIn

                // `loginOKProducer` will automatically send `.loginOK`
                testScheduler.advanceByInterval(1)

                expect(lastReply?.input) == .loginOK
                expect(lastReply?.fromState) == .loggingIn
                expect(lastReply?.toState) == .loggedIn
                expect(automaton?.state.value) == .loggedIn
            }

        }

    }
}
