//
//  ViewController.swift
//  RxAutomatonDemo
//
//  Created by Yasuhiro Inami on 2016-08-15.
//  Copyright © 2016 Yasuhiro Inami. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import RxAutomaton
import Pulsator

class AutomatonViewController: UIViewController
{
    @IBOutlet weak var diagramView: UIImageView?
    @IBOutlet weak var label: UILabel?

    @IBOutlet weak var loginButton: UIButton?
    @IBOutlet weak var logoutButton: UIButton?
    @IBOutlet weak var forceLogoutButton: UIButton?

    private var pulsator: Pulsator?

    private var _automaton: Automaton<State, Input>?

    private let _disposeBag = DisposeBag()

    deinit { logDeinit(self) }

    override func viewDidLoad()
    {
        super.viewDidLoad()

        let (textSignal, textObserver) = Observable<String>.pipe()

        /// Count-up effect.
        func countUpProducer(status: String, count: Int = 4, interval: NSTimeInterval = 1, nextInput: Input) -> Observable<Input>
        {
            return Observable<Int>.interval(interval, scheduler: MainScheduler.instance)
                .take(count)
                .scan(0) { $0.0 + 1 }
                .startWith(0)
                .map {
                    switch $0 {
                        case 0:     return "\(status)..."
                        case count: return "\(status) Done!"
                        default:    return "\(status)... (\($0))"
                    }
                }
                .doOnNext(textObserver.onNext)
                .then(value: nextInput)
        }

        let loginOKProducer = countUpProducer("Login", nextInput: .LoginOK)
        let logoutOKProducer = countUpProducer("Logout", nextInput: .LogoutOK)
        let forceLogoutOKProducer = countUpProducer("ForceLogout", nextInput: .LogoutOK)

        // NOTE: predicate style i.e. `T -> Bool` is also available.
        let canForceLogout: State -> Bool = [.LoggingIn, .LoggedIn].contains

        /// Transition mapping.
        let mappings: [Automaton<State, Input>.NextMapping] = [

          /*  Input   |   fromState => toState     |      Effect       */
          /* ----------------------------------------------------------*/
            .Login    | .LoggedOut  => .LoggingIn  | loginOKProducer,
            .LoginOK  | .LoggingIn  => .LoggedIn   | .empty(),
            .Logout   | .LoggedIn   => .LoggingOut | logoutOKProducer,
            .LogoutOK | .LoggingOut => .LoggedOut  | .empty(),

            .ForceLogout | canForceLogout => .LoggingOut | forceLogoutOKProducer
        ]

        let (inputSignal, inputObserver) = Observable<Input>.pipe()

        let automaton = Automaton(state: .LoggedOut, input: inputSignal, mapping: reduce(mappings), strategy: .Latest)
        self._automaton = automaton

        automaton.replies
            .subscribeNext { reply in
                print("received reply = \(reply)")
            }
            .addDisposableTo(_disposeBag)

        automaton.state.asObservable()
            .subscribeNext { state in
                print("current state = \(state)")
            }
            .addDisposableTo(_disposeBag)

        // Setup buttons.
        do {
            self.loginButton?.rx_tap
                .subscribeNext { _ in inputObserver.onNext(.Login) }
                .addDisposableTo(_disposeBag)

            self.logoutButton?.rx_tap
                .subscribeNext { _ in inputObserver.onNext(.Logout) }
                .addDisposableTo(_disposeBag)

            self.forceLogoutButton?.rx_tap
                .subscribeNext { _ in inputObserver.onNext(.ForceLogout) }
                .addDisposableTo(_disposeBag)
        }

        // Setup label.
        do {
            textSignal
                .bindTo(self.label!.rx_text)
                .addDisposableTo(_disposeBag)
        }

        // Setup Pulsator.
        do {
            let pulsator = _createPulsator()
            self.pulsator = pulsator

            self.diagramView?.layer.addSublayer(pulsator)

            automaton.state.asDriver()
                .map(_pulsatorColor)
                .map { $0.CGColor }
                .drive(pulsator.rx_backgroundColor)
                .addDisposableTo(_disposeBag)

            automaton.state.asDriver()
                .map(_pulsatorPosition)
                .drive(pulsator.rx_position)
                .addDisposableTo(_disposeBag)

            // Overwrite the pulsator color to red if `.ForceLogout` succeeded.
            automaton.replies
                .filter { $0.toState != nil && $0.input == .ForceLogout }
                .map { _ in UIColor.redColor().CGColor }
                .bindTo(pulsator.rx_backgroundColor)
                .addDisposableTo(_disposeBag)
        }

    }

}

// MARK: Pulsator

private func _createPulsator() -> Pulsator
{
    let pulsator = Pulsator()
    pulsator.numPulse = 5
    pulsator.radius = 100
    pulsator.animationDuration = 7
    pulsator.backgroundColor = UIColor(red: 0, green: 0.455, blue: 0.756, alpha: 1).CGColor

    pulsator.start()

    return pulsator
}

private func _pulsatorPosition(state: State) -> CGPoint
{
    switch state {
        case .LoggedOut:    return CGPoint(x: 40, y: 100)
        case .LoggingIn:    return CGPoint(x: 190, y: 20)
        case .LoggedIn:     return CGPoint(x: 330, y: 100)
        case .LoggingOut:   return CGPoint(x: 190, y: 180)
    }
}

private func _pulsatorColor(state: State) -> UIColor
{
    switch state {
        case .LoggedOut:
            return UIColor(red: 0, green: 0.455, blue: 0.756, alpha: 1)     // blue
        case .LoggingIn, .LoggingOut:
            return UIColor(red: 0.97, green: 0.82, blue: 0.30, alpha: 1)    // yellow
        case .LoggedIn:
            return UIColor(red: 0.50, green: 0.85, blue: 0.46, alpha: 1)    // green
    }
}
