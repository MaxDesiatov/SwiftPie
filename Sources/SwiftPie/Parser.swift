//
//  Created by Max Desiatov on 26/08/2021.
//

import Parsing

func reserved(_ string: String) -> StartsWith<String.UTF8View.SubSequence> {
  .init(string.utf8)
}

let parseStatement = reserved("let")

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
