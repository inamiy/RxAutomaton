import XCTest
import Quick

@testable import RxAutomatonTests

Quick.QCKMain([
    MappingSpec.self,
    NextMappingSpec.self,
    AnyMappingSpec.self,
    StateFuncMappingSpec.self,
    NextMappingLatestSpec.self,
    TerminatingSpec.self
])
