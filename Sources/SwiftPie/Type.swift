//
//  Created by Max Desiatov on 25/08/2021.
//

enum TypeError: Error {
  case typeMismatch(Type, Type)
  case unknownTypeMismatch
}

extension InferredTerm {
  func infer(
    _ i: Int,
    _ names: NameEnv,
    _ context: Context
  ) throws -> Type {
    fatalError()
  }
}

extension CheckedTerm {
  func typeCheck(
    _ i: Int,
    _ names: NameEnv,
    _ context: Context,
    _ type: Type
  ) throws {
    switch (self, type) {
    case let (.inferred(e), _):
      let inferredType = try e.infer(i, names, context)
      try inferredType.expectMatches(type)

    case let (.lambda(e), .pi(type, type1)):
      var newContext = context
      newContext[.local(i)] = type
      try e.subst(0, .free(.local(i)))
        .typeCheck(i + 1, names, newContext, type1(.free(.local(i))))

    case (.zero, .nat):
      return

    case let (.succ(k), .nat):
      try k.typeCheck(i, names, context, .nat)

    case let (.nil(a), .vec(bVal, .zero)):
      try a.typeCheck(i, names, context, .star)
      let aVal = a.eval(names, [])
      try aVal.expectMatches(bVal)

    case let (.cons(a, n, x, xs), .vec(bVal, .succ(k))):
      try a.typeCheck(i, names, context, .star)
      let aVal = a.eval(names, [])
      try aVal.expectMatches(bVal)

      try n.typeCheck(i, names, context, .nat)
      let nVal = n.eval(names, [])
      try nVal.expectMatches(k)

      try x.typeCheck(i, names, context, aVal)
      try xs.typeCheck(i, names, context, .vec(bVal, k))

    case let (.refl(a, z), .eq(bVal, xVal, yVal)):
      try a.typeCheck(i, names, context, .star)
      let aVal = a.eval(names, [])
      try aVal.expectMatches(bVal)

      try z.typeCheck(i, names, context, aVal)
      let zVal = z.eval(names, [])

      try zVal.expectMatches(xVal)
      try zVal.expectMatches(yVal)

    case let (.fZero(n), .fin(.succ(mVal))):
      try n.typeCheck(i, names, context, .nat)

      let nVal = n.eval(names, [])
      try nVal.expectMatches(mVal)

    case let (.fSucc(n, f), .fin(.succ(mVal))):
      try n.typeCheck(i, names, context, .nat)
      let nVal = n.eval(names, [])
      try nVal.expectMatches(mVal)

      try f.typeCheck(i, names, context, .fin(mVal))

    default:
      throw TypeError.unknownTypeMismatch
    }
  }
}

extension Type {
  func expectMatches(_ type: Type) throws {
    guard quote == type.quote else {
      throw TypeError.typeMismatch(self, type)
    }
  }
}
