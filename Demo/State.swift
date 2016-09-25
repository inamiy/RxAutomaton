//
//  State.swift
//  RxAutomaton
//
//  Created by Yasuhiro Inami on 2016-08-15.
//  Copyright © 2016 Yasuhiro Inami. All rights reserved.
//

enum State: String, CustomStringConvertible
{
    case loggedOut
    case loggingIn
    case loggedIn
    case loggingOut

    var description: String { return self.rawValue }
}
