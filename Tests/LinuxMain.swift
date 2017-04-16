import XCTest
import Quick

@testable import RxAutomatonTests

Quick.QCKMain([
    MappingSpec.self,
    EffectMappingSpec.self,
    AnyMappingSpec.self,
    StateFuncMappingSpec.self,
    EffectMappingLatestSpec.self,
    TerminatingSpec.self
])
