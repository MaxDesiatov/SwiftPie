//
//  Created by Max Desiatov on 26/08/2021.
//

import Parsing

typealias UTF8SubSequence = String.UTF8View.SubSequence

func reserved(_ string: String) -> StartsWith<UTF8SubSequence> {
  .init(string.utf8)
}

let identifierHead = [
  UInt8(ascii: "_"),
] + Array(UInt8(ascii: "A")...UInt8(ascii: "z"))

let identifierTail = identifierHead + Array(UInt8(ascii: "0")...UInt8(ascii: "9"))

let identifierParser =
  FirstWhere<UTF8SubSequence> { identifierHead.contains($0) }
    .take(Prefix { identifierTail.contains($0) })
    .compactMap { String(bytes: [$0] + Array($1), encoding: .utf8) }

let letBindingParser = reserved("let")
  .skip(Whitespace())
  .take(identifierParser)
  .skip(Whitespace())
  .skip(reserved("="))
  .skip(Whitespace())
  .take(parseInferredTerm)
//    .map { Statement.letBinding(identifier: $1, $2) }

let parseInferredTerm = reserved("forall")

extension CheckedTerm {
  init(_ i: Int) {
    self = i == 0 ? .zero : .succ(.init(i - 1))
  }
}

extension InferredTerm {
  init(_ i: Int) {
    self = .annotation(.init(i), .inferred(.nat))
  }
}
