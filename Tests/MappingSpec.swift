//
//  MappingSpec.swift
//  RxAutomaton
//
//  Created by Yasuhiro Inami on 2016-08-15.
//  Copyright © 2016 Yasuhiro Inami. All rights reserved.
//

import RxSwift
import RxTests
import RxAutomaton
import Quick
import Nimble

/// Tests for `(State, Input) -> State?` mapping.
class MappingSpec: QuickSpec
{
    override func spec()
    {
        typealias Automaton = RxAutomaton.Automaton<AuthState, AuthInput>
        typealias Mapping = Automaton.Mapping

        let (signal, observer) = Observable<AuthInput>.pipe()
        var automaton: Automaton?
        var lastReply: Reply<AuthState, AuthInput>?

        describe("Syntax-sugar Mapping") {

            beforeEach {
                // NOTE: predicate style i.e. `T -> Bool` is also available.
                let canForceLogout: AuthState -> Bool = [AuthState.LoggingIn, .LoggedIn].contains

                let mappings: [Mapping] = [
                    .Login    | .LoggedOut  => .LoggingIn,
                    .LoginOK  | .LoggingIn  => .LoggedIn,
                    .Logout   | .LoggedIn   => .LoggingOut,
                    .LogoutOK | .LoggingOut => .LoggedOut,

                    .ForceLogout | canForceLogout => .LoggingOut
                ]

                // NOTE: Use `concat` to combine all mappings.
                automaton = Automaton(state: .LoggedOut, input: signal, mapping: reduce(mappings))

                automaton?.replies.observeNext { reply in
                    lastReply = reply
                }

                lastReply = nil
            }

            it("`LoggedOut => LoggingIn => LoggedIn => LoggingOut => LoggedOut` succeed") {
                expect(automaton?.state.value) == .LoggedOut
                expect(lastReply).to(beNil())

                observer.sendNext(.Login)

                expect(lastReply?.input) == .Login
                expect(lastReply?.fromState) == .LoggedOut
                expect(lastReply?.toState) == .LoggingIn
                expect(automaton?.state.value) == .LoggingIn

                observer.sendNext(.LoginOK)

                expect(lastReply?.input) == .LoginOK
                expect(lastReply?.fromState) == .LoggingIn
                expect(lastReply?.toState) == .LoggedIn
                expect(automaton?.state.value) == .LoggedIn

                observer.sendNext(.Logout)

                expect(lastReply?.input) == .Logout
                expect(lastReply?.fromState) == .LoggedIn
                expect(lastReply?.toState) == .LoggingOut
                expect(automaton?.state.value) == .LoggingOut

                observer.sendNext(.LogoutOK)

                expect(lastReply?.input) == .LogoutOK
                expect(lastReply?.fromState) == .LoggingOut
                expect(lastReply?.toState) == .LoggedOut
                expect(automaton?.state.value) == .LoggedOut
            }

            it("`LoggedOut => LoggingIn ==(ForceLogout)==> LoggingOut => LoggedOut` succeed") {
                expect(automaton?.state.value) == .LoggedOut
                expect(lastReply).to(beNil())

                observer.sendNext(.Login)

                expect(lastReply?.input) == .Login
                expect(lastReply?.fromState) == .LoggedOut
                expect(lastReply?.toState) == .LoggingIn
                expect(automaton?.state.value) == .LoggingIn

                observer.sendNext(.ForceLogout)

                expect(lastReply?.input) == .ForceLogout
                expect(lastReply?.fromState) == .LoggingIn
                expect(lastReply?.toState) == .LoggingOut
                expect(automaton?.state.value) == .LoggingOut

                // fails
                observer.sendNext(.LoginOK)

                expect(lastReply?.input) == .LoginOK
                expect(lastReply?.fromState) == .LoggingOut
                expect(lastReply?.toState).to(beNil())
                expect(automaton?.state.value) == .LoggingOut

                // fails
                observer.sendNext(.Logout)

                expect(lastReply?.input) == .Logout
                expect(lastReply?.fromState) == .LoggingOut
                expect(lastReply?.toState).to(beNil())
                expect(automaton?.state.value) == .LoggingOut

                observer.sendNext(.LogoutOK)

                expect(lastReply?.input) == .LogoutOK
                expect(lastReply?.fromState) == .LoggingOut
                expect(lastReply?.toState) == .LoggedOut
                expect(automaton?.state.value) == .LoggedOut
            }

        }

        describe("Func-based Mapping") {

            beforeEach {
                let mapping: Mapping = { fromState, input in
                    switch (fromState, input) {
                        case (.LoggedOut, .Login):
                            return .LoggingIn
                        case (.LoggingIn, .LoginOK):
                            return .LoggedIn
                        case (.LoggedIn, .Logout):
                            return .LoggingOut
                        case (.LoggingOut, .LogoutOK):
                            return .LoggedOut

                        // ForceLogout
                        case (.LoggingIn, .ForceLogout), (.LoggedIn, .ForceLogout):
                            return .LoggingOut

                        default:
                            return nil
                    }
                }

                automaton = Automaton(state: .LoggedOut, input: signal, mapping: mapping)
                automaton?.replies.observeNext { reply in
                    lastReply = reply
                }

                lastReply = nil
            }

            it("`LoggedOut => LoggingIn => LoggedIn => LoggingOut => LoggedOut` succeed") {
                expect(automaton?.state.value) == .LoggedOut
                expect(lastReply).to(beNil())

                observer.sendNext(.Login)

                expect(lastReply?.input) == .Login
                expect(lastReply?.fromState) == .LoggedOut
                expect(lastReply?.toState) == .LoggingIn
                expect(automaton?.state.value) == .LoggingIn

                observer.sendNext(.LoginOK)

                expect(lastReply?.input) == .LoginOK
                expect(lastReply?.fromState) == .LoggingIn
                expect(lastReply?.toState) == .LoggedIn
                expect(automaton?.state.value) == .LoggedIn

                observer.sendNext(.Logout)

                expect(lastReply?.input) == .Logout
                expect(lastReply?.fromState) == .LoggedIn
                expect(lastReply?.toState) == .LoggingOut
                expect(automaton?.state.value) == .LoggingOut

                observer.sendNext(.LogoutOK)

                expect(lastReply?.input) == .LogoutOK
                expect(lastReply?.fromState) == .LoggingOut
                expect(lastReply?.toState) == .LoggedOut
                expect(automaton?.state.value) == .LoggedOut
            }

            it("`LoggedOut => LoggingIn ==(ForceLogout)==> LoggingOut => LoggedOut` succeed") {
                expect(automaton?.state.value) == .LoggedOut
                expect(lastReply).to(beNil())

                observer.sendNext(.Login)

                expect(lastReply?.input) == .Login
                expect(lastReply?.fromState) == .LoggedOut
                expect(lastReply?.toState) == .LoggingIn
                expect(automaton?.state.value) == .LoggingIn

                observer.sendNext(.ForceLogout)

                expect(lastReply?.input) == .ForceLogout
                expect(lastReply?.fromState) == .LoggingIn
                expect(lastReply?.toState) == .LoggingOut
                expect(automaton?.state.value) == .LoggingOut

                // fails
                observer.sendNext(.LoginOK)

                expect(lastReply?.input) == .LoginOK
                expect(lastReply?.fromState) == .LoggingOut
                expect(lastReply?.toState).to(beNil())
                expect(automaton?.state.value) == .LoggingOut

                // fails
                observer.sendNext(.Logout)

                expect(lastReply?.input) == .Logout
                expect(lastReply?.fromState) == .LoggingOut
                expect(lastReply?.toState).to(beNil())
                expect(automaton?.state.value) == .LoggingOut

                observer.sendNext(.LogoutOK)

                expect(lastReply?.input) == .LogoutOK
                expect(lastReply?.fromState) == .LoggingOut
                expect(lastReply?.toState) == .LoggedOut
                expect(automaton?.state.value) == .LoggedOut
            }

        }
    }
}
