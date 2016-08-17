//
//  Mapping+Helper.swift
//  RxAutomaton
//
//  Created by Yasuhiro Inami on 2016-08-15.
//  Copyright © 2016 Yasuhiro Inami. All rights reserved.
//

import RxSwift

/// "From-" and "to-" states represented as `.State1 => .State2` or `anyState => .State3`.
public struct Transition<State>
{
    public let fromState: State -> Bool
    public let toState: State
}

// MARK: - Custom Operators

// MARK: `=>` (Transition constructor)

infix operator => { associativity left precedence 150 } // higher than `|` (precedence 140)

public func => <State>(left: State -> Bool, right: State) -> Transition<State>
{
    return Transition(fromState: left, toState: right)
}

public func => <State: Equatable>(left: State, right: State) -> Transition<State>
{
    return { $0 == left } => right
}

// MARK: `|` (Automaton.Mapping constructor)

//infix operator | { associativity left precedence 140 }   // Comment-Out: already built-in

public func | <State, Input>(inputFunc: Input -> Bool, transition: Transition<State>) -> Automaton<State, Input>.Mapping
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

// MARK: `|` (Automaton.NextMapping constructor)

public func | <State, Input>(mapping: Automaton<State, Input>.Mapping, nextInputProducer: Observable<Input>) -> Automaton<State, Input>.NextMapping
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
/// - `let mapping = .Input0 | any => .State1`
/// - `let mapping = any | .State1 => .State2`
public func any<T>(_: T) -> Bool
{
    return true
}

/// Folds multiple `Automaton.Mapping`s into one (preceding mapping has higher priority).
public func reduce<State, Input, Mappings: SequenceType where Mappings.Generator.Element == Automaton<State, Input>.Mapping>(mappings: Mappings) -> Automaton<State, Input>.Mapping
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

/// Folds multiple `Automaton.NextMapping`s into one (preceding mapping has higher priority).
public func reduce<State, Input, Mappings: SequenceType where Mappings.Generator.Element == Automaton<State, Input>.NextMapping>(mappings: Mappings) -> Automaton<State, Input>.NextMapping
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
