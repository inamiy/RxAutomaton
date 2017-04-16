Pod::Spec.new do |s|
  s.name         = "RxAutomaton"
  s.version      = "0.2.0"
  s.summary      = "RxSwift + State Machine, inspired by Redux and Elm."
  s.homepage     = "https://github.com/inamiy/RxAutomaton"
  s.license      = { :type => "MIT", :file => "LICENSE" }
  s.author       = { "Yasuhiro Inami" => "inamiy@gmail.com" }

  s.ios.deployment_target = "8.0"
  s.osx.deployment_target = "10.10"
  s.watchos.deployment_target = "2.0"
  s.tvos.deployment_target = "9.0"

  s.source       = { :git => "https://github.com/inamiy/RxAutomaton.git", :tag => "#{s.version}" }
  s.source_files  = "Sources/**/*.swift"

  s.dependency "RxSwift", "~> 3.0"
end
