//
//  Fixtures.swift
//  RxAutomaton
//
//  Created by Yasuhiro Inami on 2016-08-15.
//  Copyright © 2016 Yasuhiro Inami. All rights reserved.
//

import RxSwift
import RxAutomaton

enum AuthState: String, CustomStringConvertible
{
    case loggedOut
    case loggingIn
    case loggedIn
    case loggingOut

    var description: String { return self.rawValue }
}

/// - Note:
/// `LoginOK` and `LogoutOK` should only be used internally
/// (but Swift can't make them as `private case`)
enum AuthInput: String, CustomStringConvertible
{
    case login
    case loginOK
    case logout
    case forceLogout
    case logoutOK

    var description: String { return self.rawValue }
}

enum MyState
{
    case state0, state1, state2
}

enum MyInput
{
    case input0, input1, input2
}

// MARK: Extensions

extension Event
{
    public var isCompleting: Bool
    {
        switch self {
            case .next, .error:
                return false

            case .completed:
                return true
        }
    }

    // Comment-Out: RxSwift doesn't have `.Interrupted`.
//    public var isInterrupting: Bool
//    {
//        switch self {
//            case .Next, .Failed, .Completed:
//                return false
//
//            case .Interrupted:
//                return true
//        }
//    }
}
