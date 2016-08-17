//
//  TerminatingSpec.swift
//  RxAutomaton
//
//  Created by Yasuhiro Inami on 2016-08-15.
//  Copyright © 2016 Yasuhiro Inami. All rights reserved.
//

import RxSwift
import RxAutomaton
import Quick
import Nimble

class TerminatingSpec: QuickSpec
{
    override func spec()
    {
        typealias Automaton = RxAutomaton.Automaton<MyState, MyInput>
        typealias Mapping = Automaton.Mapping

        var automaton: Automaton?
        var lastReply: Reply<MyState, MyInput>?
        var lastRepliesEvent: Event<Reply<MyState, MyInput>>?

        /// Flag for internal nextProducer `sendInput1And2AfterDelay` disposed.
//        var nextProducerDisposed: Bool?

        var signal: Observable<MyInput>!
        var observer: AnyObserver<MyInput>!
        var testScheduler: TestScheduler!

        describe("Deinit") {

            beforeEach {
                testScheduler = TestScheduler()
                let (signal_, observer_) = Observable<MyInput>.pipe()
                signal = signal_
                observer = observer_

                let sendInput1And2AfterDelay: Observable<MyInput> = [
                    Observable.just(.Input1).delay(1, onScheduler: testScheduler),
                    Observable.just(.Input2).delay(1, onScheduler: testScheduler),
                ].concat()

                let mappings: [Automaton.NextMapping] = [
                    .Input0 | .State0 => .State1 | sendInput1And2AfterDelay,
                    .Input1 | .State1 => .State2 | .empty(),
                    .Input2 | .State2 => .State0 | .empty()
                ]

                // strategy = `.Merge`
                automaton = Automaton(state: .State0, input: signal, mapping: reduce(mappings), strategy: .Merge)

                automaton?.replies.observe { event in
                    lastRepliesEvent = event

                    if let reply = event.element {
                        lastReply = reply
                    }
                }

                lastReply = nil
                lastRepliesEvent = nil
//                nextProducerDisposed = false
            }

            describe("Automaton deinit") {

                it("automaton deinits before sending input") {
                    expect(automaton?.state.value) == .State0
                    expect(lastReply).to(beNil())
                    expect(lastRepliesEvent).to(beNil())

                    weak var weakAutomaton = automaton
                    automaton = nil

                    expect(weakAutomaton).to(beNil())
                    expect(lastReply).to(beNil())
                    expect(lastRepliesEvent?.isCompleting) == true
                }

                it("automaton deinits while sending input") {
                    expect(automaton?.state.value) == .State0
                    expect(lastReply).to(beNil())
                    expect(lastRepliesEvent).to(beNil())
//                    expect(nextProducerDisposed) == false

                    observer.sendNext(.Input0)

                    expect(automaton?.state.value) == .State1
                    expect(lastReply?.input) == .Input0
                    expect(lastRepliesEvent?.isTerminating) == false
//                    expect(nextProducerDisposed) == false

                    // `sendInput1And2AfterDelay` will automatically send `.Input1` at this point
                    testScheduler.advanceByInterval(1)

                    expect(automaton?.state.value) == .State2
                    expect(lastReply?.input) == .Input1
                    expect(lastRepliesEvent?.isTerminating) == false
//                    expect(nextProducerDisposed) == false

                    weak var weakAutomaton = automaton
                    automaton = nil

                    expect(weakAutomaton).to(beNil())
                    expect(lastReply?.input) == .Input1
                    expect(lastRepliesEvent?.isCompleting) == true  // isCompleting
//                    expect(nextProducerDisposed) == true

                    // If `sendInput1And2AfterDelay` is still alive, it will send `.Input2` at this point,
                    // but it's already interrupted because `automaton` is deinited.
                    testScheduler.advanceByInterval(1)

                    // Last input should NOT change.
                    expect(lastReply?.input) == .Input1
                }

            }

            // This basically behaves similar to `automaton.deinit`,
            // except `replies` will emit `.Interrupted` instead of `.Completed`.
//            describe("inputSignal sendInterrupted") {
//
//                it("inputSignal sendInterrupted before sending input") {
//                    expect(automaton?.state.value) == .State0
//                    expect(lastReply).to(beNil())
//                    expect(lastRepliesEvent).to(beNil())
//
//                    observer.sendInterrupted()
//
//                    expect(automaton?.state.value) == .State0
//                    expect(lastReply).to(beNil())
////                    expect(lastRepliesEvent?.isInterrupting) == true
//                }
//
//                it("inputSignal sendInterrupted while sending input") {
//                    expect(automaton?.state.value) == .State0
//                    expect(automaton).toNot(beNil())
//                    expect(lastReply).to(beNil())
//                    expect(lastRepliesEvent).to(beNil())
//                    expect(nextProducerDisposed) == false
//
//                    observer.sendNext(.Input0)
//
//                    expect(automaton?.state.value) == .State1
//                    expect(lastReply?.input) == .Input0
//                    expect(lastRepliesEvent?.isTerminating) == false
//                    expect(nextProducerDisposed) == false
//
//                    // `sendInput1And2AfterDelay` will automatically send `.Input1` at this point
//                    testScheduler.advanceByInterval(1)
//
//                    expect(automaton?.state.value) == .State2
//                    expect(lastReply?.input) == .Input1
//                    expect(lastRepliesEvent?.isTerminating) == false
//                    expect(nextProducerDisposed) == false
//
//                    observer.sendInterrupted()
//
//                    expect(automaton?.state.value) == .State2
//                    expect(lastReply?.input) == .Input1
////                    expect(lastRepliesEvent?.isInterrupting) == true    // interrupting, not isCompleting
//                    expect(nextProducerDisposed) == true
//
//                    // If `sendInput1And2AfterDelay` is still alive, it will send `.Input2` at this point,
//                    // but it's already interrupted because of `sendInterrupted`.
//                    testScheduler.advanceByInterval(1)
//
//                    // Last state & input should NOT change.
//                    expect(automaton?.state.value) == .State2
//                    expect(lastReply?.input) == .Input1
//                }
//
//            }

            // Unlike `automaton.deinit` or `inputSignal` sending `.Interrupted`,
            // inputSignal` sending `.Completed` does NOT cancel internal nextProducer,
            // i.e. `sendInput1And2AfterDelay`.
            describe("inputSignal sendCompleted") {

                it("inputSignal sendCompleted before sending input") {
                    expect(automaton?.state.value) == .State0
                    expect(lastReply).to(beNil())
                    expect(lastRepliesEvent).to(beNil())

                    observer.sendCompleted()

                    expect(automaton?.state.value) == .State0
                    expect(lastReply).to(beNil())
                    expect(lastRepliesEvent?.isCompleting) == true
                }

                it("inputSignal sendCompleted while sending input") {
                    expect(automaton?.state.value) == .State0
                    expect(lastReply).to(beNil())
                    expect(lastRepliesEvent).to(beNil())
//                    expect(nextProducerDisposed) == false

                    observer.sendNext(.Input0)

                    expect(automaton?.state.value) == .State1
                    expect(lastReply?.input) == .Input0
                    expect(lastRepliesEvent?.isTerminating) == false
//                    expect(nextProducerDisposed) == false

                    // `sendInput1And2AfterDelay` will automatically send `.Input1` at this point.
                    testScheduler.advanceByInterval(1)

                    expect(automaton?.state.value) == .State2
                    expect(lastReply?.input) == .Input1
                    expect(lastRepliesEvent?.isTerminating) == false
//                    expect(nextProducerDisposed) == false

                    observer.sendCompleted()

                    // Not completed yet because `sendInput1And2AfterDelay` is still in progress.
                    expect(automaton?.state.value) == .State2
                    expect(lastReply?.input) == .Input1
                    expect(lastRepliesEvent?.isTerminating) == false
//                    expect(nextProducerDisposed) == false

                    // `sendInput1And2AfterDelay` will automatically send `.Input2` at this point.
                    testScheduler.advanceByInterval(2)

                    print(automaton?.state.value)
                    print(lastRepliesEvent)

                    // Last state & input should change.
                    expect(automaton?.state.value) == .State0
                    expect(lastReply?.input) == .Input2
                    expect(lastRepliesEvent?.isCompleting) == true
//                    expect(nextProducerDisposed) == true
                }

            }

        }

    }
}
