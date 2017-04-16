//
//  Mapping+Helper.swift
//  RxAutomaton
//
//  Created by Yasuhiro Inami on 2016-08-15.
//  Copyright © 2016 Yasuhiro Inami. All rights reserved.
//

import RxSwift

/// "From-" and "to-" states represented as `.state1 => .state2` or `anyState => .state3`.
public struct Transition<State>
{
    public let fromState: (State) -> Bool
    public let toState: State
}

// MARK: - Custom Operators

// MARK: `=>` (Transition constructor)

precedencegroup TransitionPrecedence {
    associativity: left
    higherThan: AdditionPrecedence
}
infix operator => : TransitionPrecedence    // higher than `|`

public func => <State>(left: @escaping (State) -> Bool, right: State) -> Transition<State>
{
    return Transition(fromState: left, toState: right)
}

public func => <State: Equatable>(left: State, right: State) -> Transition<State>
{
    return { $0 == left } => right
}

// MARK: `|` (Automaton.Mapping constructor)

//infix operator | { associativity left precedence 140 }   // Comment-Out: already built-in

public func | <State, Input>(inputFunc: @escaping (Input) -> Bool, transition: Transition<State>) -> Automaton<State, Input>.Mapping
{
    return { fromState, input in
        if inputFunc(input) && transition.fromState(fromState) {
            return transition.toState
        }
        else {
            return nil
        }
    }
}

public func | <State, Input: Equatable>(input: Input, transition: Transition<State>) -> Automaton<State, Input>.Mapping
{
    return { $0 == input } | transition
}

public func | <State, Input>(inputFunc: @escaping (Input) -> Bool, transition: @escaping (State) -> State) -> Automaton<State, Input>.Mapping
{
    return { fromState, input in
        if inputFunc(input) {
            return transition(fromState)
        }
        else {
            return nil
        }
    }
}

public func | <State, Input: Equatable>(input: Input, transition: @escaping (State) -> State) -> Automaton<State, Input>.Mapping
{
    return { $0 == input } | transition
}

// MARK: `|` (Automaton.EffectMapping constructor)

public func | <State, Input>(mapping: @escaping Automaton<State, Input>.Mapping, nextInputProducer: Observable<Input>) -> Automaton<State, Input>.EffectMapping
{
    return { fromState, input in
        if let toState = mapping(fromState, input) {
            return (toState, nextInputProducer)
        }
        else {
            return nil
        }
    }
}

// MARK: Functions

/// Helper for "any state" or "any input" mappings, e.g.
/// - `let mapping = .input0 | any => .state1`
/// - `let mapping = any | .state1 => .state2`
public func any<T>(_: T) -> Bool
{
    return true
}

/// Folds multiple `Automaton.Mapping`s into one (preceding mapping has higher priority).
public func reduce<State, Input, Mappings: Sequence>(_ mappings: Mappings) -> Automaton<State, Input>.Mapping
    where Mappings.Iterator.Element == Automaton<State, Input>.Mapping
{
    return { fromState, input in
        for mapping in mappings {
            if let toState = mapping(fromState, input) {
                return toState
            }
        }
        return nil
    }
}

/// Folds multiple `Automaton.EffectMapping`s into one (preceding mapping has higher priority).
public func reduce<State, Input, Mappings: Sequence>(_ mappings: Mappings) -> Automaton<State, Input>.EffectMapping
    where Mappings.Iterator.Element == Automaton<State, Input>.EffectMapping
{
    return { fromState, input in
        for mapping in mappings {
            if let tuple = mapping(fromState, input) {
                return tuple
            }
        }
        return nil
    }
}
