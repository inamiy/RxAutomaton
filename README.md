# RxAutomaton

[RxSwift](https://github.com/ReactiveX/RxSwift) port of [ReactiveAutomaton](https://github.com/inamiy/ReactiveAutomaton) (State Machine).

>
> ### Terminology
>
> Whenever the word "signal" or "(signal) producer" appears (derived from [ReactiveCocoa](https://github.com/ReactiveCocoa/ReactiveCocoa)), they mean "hot-observable" and "cold-observable".

## Example

(Demo app is bundled in the project)

![](Assets/login-diagram.png)

To make a state transition diagram like above _with additional effects_, follow these steps:

```swift
// 1. Define `State`s and `Input`s.
enum State {
    case LoggedOut, LoggingIn, LoggedIn, LoggingOut
}

enum Input {
    case Login, LoginOK, Logout, LogoutOK
    case ForceLogout
}

// Additional effects (`Observable`s) while state-transitioning.
// (NOTE: Use `Observable.empty()` for no effect)
let loginOKProducer = /* show UI, setup DB, request APIs, ..., and send `Input.LoginOK` */
let logoutOKProducer = /* show UI, clear cache, cancel APIs, ..., and send `Input.LogoutOK` */
let forceLogoutOKProducer = /* do something more special, ..., and send `Input.LogoutOK` */

let canForceLogout: State -> Bool = [.LoggingIn, .LoggedIn].contains

// 2. Setup state-transition mappings.
let mappings: [Automaton<State, Input>.NextMapping] = [

  /*  Input   |   fromState => toState     |      Effect       */
  /* ----------------------------------------------------------*/
    .Login    | .LoggedOut  => .LoggingIn  | loginOKProducer,
    .LoginOK  | .LoggingIn  => .LoggedIn   | .empty(),
    .Logout   | .LoggedIn   => .LoggingOut | logoutOKProducer,
    .LogoutOK | .LoggingOut => .LoggedOut  | .empty(),

    .ForceLogout | canForceLogout => .LoggingOut | forceLogoutOKProducer
]

// 3. Prepare input pipe for sending `Input` to `Automaton`.
let (inputSignal, inputObserver) = Observable<Input>.pipe()

// 4. Setup `Automaton`.
let automaton = Automaton(
    state: .LoggedOut,
    input: inputSignal,
    mapping: reduce(mappings),  // combine mappings using `reduce` helper
    strategy: .Latest   // NOTE: `.Latest` cancels previous running effect
)

// Observe state-transition replies (`.Success` or `.Failure`).
automaton.replies.subscribeNext { reply in
    print("received reply = \(reply)")
}

// Observe current state changes.
automaton.state.asObservable().subscribeNext { state in
    print("current state = \(state)")
}
```

And let's test!

```swift
let send = inputObserver.onNext

expect(automaton.state.value) == .LoggedIn    // already logged in
send(Input.Logout)
expect(automaton.state.value) == .LoggingOut  // logging out...
// `logoutOKProducer` will automatically send `Input.LogoutOK` later
// and transit to `State.LoggedOut`.

expect(automaton.state.value) == .LoggedOut   // already logged out
send(Input.Login)
expect(automaton.state.value) == .LoggingIn   // logging in...
// `loginOKProducer` will automatically send `Input.LoginOK` later
// and transit to `State.LoggedIn`.

// 👨🏽 < But wait, there's more!
// Let's send `Input.ForceLogout` immediately after `State.LoggingIn`.

send(Input.ForceLogout)                       // 💥💣💥
expect(automaton.state.value) == .LoggingOut  // logging out...
// `forceLogoutOKProducer` will automatically send `Input.LogoutOK` later
// and transit to `State.LoggedOut`.
```

## License

[MIT](LICENSE)
