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

/// NextMapping tests with `strategy = .Latest`.
class NextMappingLatestSpec: QuickSpec
{
    override func spec()
    {
        typealias Automaton = RxAutomaton.Automaton<AuthState, AuthInput>
        typealias NextMapping = Automaton.NextMapping

        let (signal, observer) = Observable<AuthInput>.pipe()
        var automaton: Automaton?
        var lastReply: Reply<AuthState, AuthInput>?

        describe("strategy = `.Latest`") {

            var testScheduler: TestScheduler!

            beforeEach {
                testScheduler = TestScheduler()

                /// Sends `.LoginOK` after delay, simulating async work during `.LoggingIn`.
                let loginOKProducer =
                    Observable.just(AuthInput.LoginOK)
                        .delay(1, onScheduler: testScheduler)

                /// Sends `.LogoutOK` after delay, simulating async work during `.LoggingOut`.
                let logoutOKProducer =
                    Observable.just(AuthInput.LogoutOK)
                        .delay(1, onScheduler: testScheduler)

                let mappings: [Automaton.NextMapping] = [
                    .Login    | .LoggedOut  => .LoggingIn  | loginOKProducer,
                    .LoginOK  | .LoggingIn  => .LoggedIn   | .empty(),
                    .Logout   | .LoggedIn   => .LoggingOut | logoutOKProducer,
                    .LogoutOK | .LoggingOut => .LoggedOut  | .empty(),
                ]

                // strategy = `.Latest`
                automaton = Automaton(state: .LoggedOut, input: signal, mapping: reduce(mappings), strategy: .Latest)

                automaton?.replies.observeNext { reply in
                    lastReply = reply
                }

                lastReply = nil
            }

            it("`strategy = .Latest` should not interrupt inner next-producers when transition fails") {
                expect(automaton?.state.value) == .LoggedOut
                expect(lastReply).to(beNil())

                observer.sendNext(.Login)

                expect(lastReply?.input) == .Login
                expect(lastReply?.fromState) == .LoggedOut
                expect(lastReply?.toState) == .LoggingIn
                expect(automaton?.state.value) == .LoggingIn

                testScheduler.advanceByInterval(0.1)

                // fails (`loginOKProducer` will not be interrupted)
                observer.sendNext(.Login)

                expect(lastReply?.input) == .Login
                expect(lastReply?.fromState) == .LoggingIn
                expect(lastReply?.toState).to(beNil())
                expect(automaton?.state.value) == .LoggingIn

                // `loginOKProducer` will automatically send `.LoginOK`
                testScheduler.advanceByInterval(1)

                expect(lastReply?.input) == .LoginOK
                expect(lastReply?.fromState) == .LoggingIn
                expect(lastReply?.toState) == .LoggedIn
                expect(automaton?.state.value) == .LoggedIn
            }

        }

    }
}
