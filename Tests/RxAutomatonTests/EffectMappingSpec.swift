//
//  EffectMappingSpec.swift
//  RxAutomaton
//
//  Created by Yasuhiro Inami on 2016-08-15.
//  Copyright © 2016 Yasuhiro Inami. All rights reserved.
//

import RxSwift
import RxTest
import RxAutomaton
import Quick
import Nimble

/// Tests for `(State, Input) -> (State, Output)?` mapping
/// where `Output = Observable<Input>`.
class EffectMappingSpec: QuickSpec
{
    override func spec()
    {
        typealias Automaton = RxAutomaton.Automaton<AuthState, AuthInput>
        typealias EffectMapping = Automaton.EffectMapping

        let (signal, observer) = Observable<AuthInput>.pipe()
        var automaton: Automaton?
        var lastReply: Reply<AuthState, AuthInput>?
        var testScheduler: TestScheduler!

        describe("Syntax-sugar EffectMapping") {

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

                // strategy = `.merge`
                automaton = Automaton(state: .loggedOut, input: signal, mapping: reduce(mappings), strategy: .merge)

                automaton?.replies.observeValues { reply in
                    lastReply = reply
                }

                lastReply = nil
            }

            it("`LoggedOut => LoggingIn => LoggedIn => LoggingOut => LoggedOut` succeed") {
                expect(automaton?.state.value) == .loggedOut
                expect(lastReply).to(beNil())

                observer.send(next: .login)

                expect(lastReply?.input) == .login
                expect(lastReply?.fromState) == .loggedOut
                expect(lastReply?.toState) == .loggingIn
                expect(automaton?.state.value) == .loggingIn

                // `loginOKProducer` will automatically send `.loginOK`
                testScheduler.advanceByInterval(1)

                expect(lastReply?.input) == .loginOK
                expect(lastReply?.fromState) == .loggingIn
                expect(lastReply?.toState) == .loggedIn
                expect(automaton?.state.value) == .loggedIn

                observer.send(next: .logout)

                expect(lastReply?.input) == .logout
                expect(lastReply?.fromState) == .loggedIn
                expect(lastReply?.toState) == .loggingOut
                expect(automaton?.state.value) == .loggingOut

                // `logoutOKProducer` will automatically send `.logoutOK`
                testScheduler.advanceByInterval(1)

                expect(lastReply?.input) == .logoutOK
                expect(lastReply?.fromState) == .loggingOut
                expect(lastReply?.toState) == .loggedOut
                expect(automaton?.state.value) == .loggedOut
            }

        }
        
        describe("Edge Invocation") {
            var subscriptionsCount = 0
            
            beforeEach {
                subscriptionsCount = 0
                
                // To reproduce the bug we need a plain cold observable
                let loginOKProducer = Observable.just(AuthInput.loginOK)
                    .do(onSubscribe: { subscriptionsCount += 1 })
                
                let mappings: [Automaton.EffectMapping] = [
                    .login    | .loggedOut  => .loggingIn  | loginOKProducer
                ]
                
                automaton = Automaton(state: .loggedOut, input: signal, mapping: reduce(mappings), strategy: .merge)
            }
            
            describe("loggedOut  => .loggingIn") {
                it("subscribes to testableLoginOKProducer only once") {
                    observer.onNext(.login)
                    expect(subscriptionsCount) == 1
                }
            }
        }
        
        describe("Func-based EffectMapping") {

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

                let mapping: EffectMapping = { fromState, input in
                    switch (fromState, input) {
                        case (.loggedOut, .login):
                            return (.loggingIn, loginOKProducer)
                        case (.loggingIn, .loginOK):
                            return (.loggedIn, .empty())
                        case (.loggedIn, .logout):
                            return (.loggingOut, logoutOKProducer)
                        case (.loggingOut, .logoutOK):
                            return (.loggedOut, .empty())
                        default:
                            return nil
                    }
                }

                // strategy = `.merge`
                automaton = Automaton(state: .loggedOut, input: signal, mapping: mapping, strategy: .merge)

                automaton?.replies.observeValues { reply in
                    lastReply = reply
                }

                lastReply = nil
            }

            it("`LoggedOut => LoggingIn => LoggedIn => LoggingOut => LoggedOut` succeed") {
                expect(automaton?.state.value) == .loggedOut
                expect(lastReply).to(beNil())

                observer.send(next: .login)

                expect(lastReply?.input) == .login
                expect(lastReply?.fromState) == .loggedOut
                expect(lastReply?.toState) == .loggingIn
                expect(automaton?.state.value) == .loggingIn

                // `loginOKProducer` will automatically send `.loginOK`
                testScheduler.advanceByInterval(1)

                expect(lastReply?.input) == .loginOK
                expect(lastReply?.fromState) == .loggingIn
                expect(lastReply?.toState) == .loggedIn
                expect(automaton?.state.value) == .loggedIn

                observer.send(next: .logout)

                expect(lastReply?.input) == .logout
                expect(lastReply?.fromState) == .loggedIn
                expect(lastReply?.toState) == .loggingOut
                expect(automaton?.state.value) == .loggingOut

                // `logoutOKProducer` will automatically send `.logoutOK`
                testScheduler.advanceByInterval(1)

                expect(lastReply?.input) == .logoutOK
                expect(lastReply?.fromState) == .loggingOut
                expect(lastReply?.toState) == .loggedOut
                expect(automaton?.state.value) == .loggedOut
            }

        }

        /// https://github.com/inamiy/RxAutomaton/issues/3
        describe("Additional effect should be called only once per input") {

            var effectCallCount = 0

            beforeEach {
                testScheduler = TestScheduler()
                effectCallCount = 0

                /// Sends `.loginOK` after delay, simulating async work during `.loggingIn`.
                let loginOKProducer =
                    Observable<AuthInput>.create { observer in
                        effectCallCount += 1
                        return testScheduler.scheduleRelative((), dueTime: .milliseconds(100), action: { () -> Disposable in
                            observer.send(next: .loginOK)
                            observer.sendCompleted()
                            return Disposables.create()
                        })
                    }

                let mappings: [Automaton.EffectMapping] = [
                    .login    | .loggedOut  => .loggingIn  | loginOKProducer,
                    .loginOK  | .loggingIn  => .loggedIn   | .empty(),
                ]

                // strategy = `.merge`
                automaton = Automaton(state: .loggedOut, input: signal, mapping: reduce(mappings), strategy: .merge)

                _ = automaton?.replies.observeValues { reply in
                    lastReply = reply
                }

                lastReply = nil
            }

            it("`LoggedOut => LoggingIn => LoggedIn => LoggingOut => LoggedOut` succeed") {
                expect(automaton?.state.value) == .loggedOut
                expect(lastReply).to(beNil())
                expect(effectCallCount) == 0

                observer.send(next: .login)

                expect(lastReply?.input) == .login
                expect(lastReply?.fromState) == .loggedOut
                expect(lastReply?.toState) == .loggingIn
                expect(automaton?.state.value) == .loggingIn
                expect(effectCallCount) == 1

                // `loginOKProducer` will automatically send `.loginOK`
                testScheduler.advanceByInterval(1)

                expect(lastReply?.input) == .loginOK
                expect(lastReply?.fromState) == .loggingIn
                expect(lastReply?.toState) == .loggedIn
                expect(automaton?.state.value) == .loggedIn
                expect(effectCallCount) == 1
            }

        }

    }
}
