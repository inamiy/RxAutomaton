//
//  Helpers.swift
//  RxAutomaton
//
//  Created by Yasuhiro Inami on 2016-08-15.
//  Copyright © 2016 Yasuhiro Inami. All rights reserved.
//

import QuartzCore
import RxSwift
import RxCocoa

func logDeinit(object: AnyObject)
{
    let addr = String(format: "%p", unsafeAddressOf(object))
    print("\n", "[deinit] \(object) \(addr)", "\n")
}

// MARK: CoreAnimation

extension CALayer
{
    public var rx_position: AnyObserver<CGPoint> {
        return UIBindingObserver(UIElement: self) { layer, value in
            layer.position = value
        }.asObserver()
    }

    public var rx_hidden: AnyObserver<Bool> {
        return UIBindingObserver(UIElement: self) { layer, value in
            layer.hidden = value
        }.asObserver()
    }

    public var rx_backgroundColor: AnyObserver<CGColor?> {
        return UIBindingObserver(UIElement: self) { layer, value in
            layer.backgroundColor = value
        }.asObserver()
    }
}
