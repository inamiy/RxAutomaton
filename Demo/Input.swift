//
//  Input.swift
//  RxAutomaton
//
//  Created by Yasuhiro Inami on 2016-08-15.
//  Copyright © 2016 Yasuhiro Inami. All rights reserved.
//

import Foundation

/// - Note:
/// `LoginOK` and `LogoutOK` should only be used internally
/// (but Swift can't make them as `private case`)
enum Input: String, CustomStringConvertible
{
    case login
    case loginOK
    case logout
    case forceLogout
    case logoutOK

    var description: String { return self.rawValue }
}
