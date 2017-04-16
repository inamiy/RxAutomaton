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

    override func viewDidLoad()
    {
        super.viewDidLoad()

        let (textSignal, textObserver) = Observable<String?>.pipe()

        /// Count-up effect.
        func countUpProducer(status: String, count: Int = 4, interval: TimeInterval = 1, nextInput: Input) -> Observable<Input>
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
                .do(onNext: textObserver.onNext)
                .then(value: nextInput)
        }

        let loginOKProducer = countUpProducer(status: "Login", nextInput: .loginOK)
        let logoutOKProducer = countUpProducer(status: "Logout", nextInput: .logoutOK)
        let forceLogoutOKProducer = countUpProducer(status: "ForceLogout", nextInput: .logoutOK)

        // NOTE: predicate style i.e. `T -> Bool` is also available.
        let canForceLogout: (State) -> Bool = [.loggingIn, .loggedIn].contains

        /// Transition mapping.
        let mappings: [Automaton<State, Input>.EffectMapping] = [

          /*  Input   |   fromState => toState     |      Effect       */
          /* ----------------------------------------------------------*/
            .login    | .loggedOut  => .loggingIn  | loginOKProducer,
            .loginOK  | .loggingIn  => .loggedIn   | .empty(),
            .logout   | .loggedIn   => .loggingOut | logoutOKProducer,
            .logoutOK | .loggingOut => .loggedOut  | .empty(),

            .forceLogout | canForceLogout => .loggingOut | forceLogoutOKProducer
        ]

        let (inputSignal, inputObserver) = Observable<Input>.pipe()

        let automaton = Automaton(state: .loggedOut, input: inputSignal, mapping: reduce(mappings), strategy: .latest)
        self._automaton = automaton

        automaton.replies
            .subscribe(onNext: { reply in
                print("received reply = \(reply)")
            })
            .addDisposableTo(_disposeBag)

        automaton.state.asObservable()
            .subscribe(onNext: { state in
                print("current state = \(state)")
            })
            .addDisposableTo(_disposeBag)

        // Setup buttons.
        do {
            self.loginButton?.rx.tap
                .subscribe(onNext: { _ in inputObserver.onNext(.login) })
                .addDisposableTo(_disposeBag)

            self.logoutButton?.rx.tap
                .subscribe(onNext: { _ in inputObserver.onNext(.logout) })
                .addDisposableTo(_disposeBag)

            self.forceLogoutButton?.rx.tap
                .subscribe(onNext: { _ in inputObserver.onNext(.forceLogout) })
                .addDisposableTo(_disposeBag)
        }

        // Setup label.
        do {
            textSignal
                .bindTo(self.label!.rx.text)
                .addDisposableTo(_disposeBag)
        }

        // Setup Pulsator.
        do {
            let pulsator = _createPulsator()
            self.pulsator = pulsator

            self.diagramView?.layer.addSublayer(pulsator)

            automaton.state.asDriver()
                .map(_pulsatorColor)
                .map { $0.cgColor }
                .drive(pulsator.rx_backgroundColor)
                .addDisposableTo(_disposeBag)

            automaton.state.asDriver()
                .map(_pulsatorPosition)
                .drive(pulsator.rx_position)
                .addDisposableTo(_disposeBag)

            // Overwrite the pulsator color to red if `.forceLogout` succeeded.
            automaton.replies
                .filter { $0.toState != nil && $0.input == .forceLogout }
                .map { _ in UIColor.red.cgColor }
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
    pulsator.backgroundColor = UIColor(red: 0, green: 0.455, blue: 0.756, alpha: 1).cgColor

    pulsator.start()

    return pulsator
}

private func _pulsatorPosition(state: State) -> CGPoint
{
    switch state {
        case .loggedOut:    return CGPoint(x: 40, y: 100)
        case .loggingIn:    return CGPoint(x: 190, y: 20)
        case .loggedIn:     return CGPoint(x: 330, y: 100)
        case .loggingOut:   return CGPoint(x: 190, y: 180)
    }
}

private func _pulsatorColor(state: State) -> UIColor
{
    switch state {
        case .loggedOut:
            return UIColor(red: 0, green: 0.455, blue: 0.756, alpha: 1)     // blue
        case .loggingIn, .loggingOut:
            return UIColor(red: 0.97, green: 0.82, blue: 0.30, alpha: 1)    // yellow
        case .loggedIn:
            return UIColor(red: 0.50, green: 0.85, blue: 0.46, alpha: 1)    // green
    }
}
