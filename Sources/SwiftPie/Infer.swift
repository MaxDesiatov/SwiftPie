//
//  Created by Max Desiatov on 26/08/2021.
//

extension InferredTerm {
  func infer(_ i: Int, _ names: NameEnv, _ context: Context) throws -> Type {
    switch self {
    case let .annotation(e, typeTerm):
      try typeTerm.typeCheck(i, names, context, .star)
      let type = typeTerm.eval(names, [])

      try e.typeCheck(i, names, context, type)

      return type

    case .star:
      // This makes the type system unsound. We need to support
      // [cumulativity](https://idris2.readthedocs.io/en/latest/tutorial/miscellany.html#cumulativity) to fix it.
      return .star

    case let .pi(typeTerm, typeTerm1):
      try typeTerm.typeCheck(i, names, context, .star)
      let type = typeTerm.eval(names, [])

      var newContext = context
      newContext[.local(i)] = type
      try typeTerm1.subst(0, .free(.local(i)))
        .typeCheck(i + 1, names, newContext, .star)
      return .star

    case let .free(x):
      guard let type = context[x] else {
        throw PieError.unknownIdentifier(x)
      }

      return type

    case let .dollarOperator(e1, e2):
      switch try e1.infer(i, names, context) {
      case let .pi(type, type1):
        try e2.typeCheck(i, names, context, type)
        return type1(e2.eval(names, []))
      default:
        throw PieError.illegalApplication
      }

    case .nat:
      return .star

    case let .natElim(m, mz, ms, n):
      try m.typeCheck(i, names, context, .pi(.nat) { _ in .star })
      let mVal = m.eval(names, [])
      try mz.typeCheck(i, names, context, mVal.apply(.zero))
      try ms.typeCheck(i, names, context, .pi(.nat) { k in .pi(mVal.apply(k)) { _ in mVal.apply(.succ(k)) } })
      try n.typeCheck(i, names, context, .nat)
      let nVal = n.eval(names, [])
      return mVal.apply(nVal)

    case let .vec(a, n):
      try a.typeCheck(i, names, context, .star)
      try n.typeCheck(i, names, context, .nat)
      return .star

    case let .vecElim(a, m, mn, mc, n, vs):
      try a.typeCheck(i, names, context, .star)
      let aVal = a.eval(names, [])

      try m.typeCheck(i, names, context, .pi(.nat) { n in .pi(.vec(aVal, n)) { _ in .star } })
      let mVal = m.eval(names, [])

      try mn.typeCheck(i, names, context, [.zero, .nil(aVal)].reduce(mVal) { $0.apply($1) })

      try mc.typeCheck(i, names, context, .pi(.nat) { n in
        .pi(aVal) { y in
          .pi(.vec(aVal, n)) { ys in
            .pi([n, ys].reduce(mVal) { $0.apply($1) }) { _ in
              [.succ(n), .cons(aVal, n, y, ys)].reduce(mVal) { $0.apply($1) }
            }
          }
        }
      })

      try n.typeCheck(i, names, context, .nat)
      let nVal = n.eval(names, [])

      try vs.typeCheck(i, names, context, .vec(aVal, nVal))
      let vsVal = vs.eval(names, [])

      return [nVal, vsVal].reduce(mVal) { $0.apply($1) }

    case let .eq(a, x, y):
      try a.typeCheck(i, names, context, .star)
      let aVal = a.eval(names, [])

      try x.typeCheck(i, names, context, aVal)
      try y.typeCheck(i, names, context, aVal)

      return .star

    case let .eqElim(a, m, mr, x, y, eq):
      try a.typeCheck(i, names, context, .star)
      let aVal = a.eval(names, [])

      try m.typeCheck(i, names, context, .pi(aVal) { x in
        .pi(aVal) { y in
          .pi(.eq(aVal, x, y)) { _ in .star }
        }
      })
      let mVal = m.eval(names, [])

      try mr.typeCheck(
        i,
        names,
        context,
        .pi(aVal) { x in [x, x, .refl(aVal, x)].reduce(mVal) { $0.apply($1) } }
      )

      try x.typeCheck(i, names, context, aVal)
      let xVal = x.eval(names, [])

      try y.typeCheck(i, names, context, aVal)
      let yVal = y.eval(names, [])

      try eq.typeCheck(i, names, context, .eq(aVal, xVal, yVal))
      let eqVal = eq.eval(names, [])

      return [xVal, yVal, eqVal].reduce(mVal) { $0.apply($1) }

    case let .fin(n):
      try n.typeCheck(i, names, context, .nat)

      return .star

    case let .finElim(m, mz, ms, n, f):
      try m.typeCheck(i, names, context, .pi(.nat) { k in .pi(.fin(k)) { _ in .star } })
      let mVal = m.eval(names, [])

      try n.typeCheck(i, names, context, .nat)
      let nVal = n.eval(names, [])

      // FIXME: was rewritten from `cType_ ii g mz (VPi_ VNat_ (\k -> mVal `vapp_` VSucc_ k `vapp_` VFZero_ k))`
      // Is `vapp_` left associative? How does that really parse?
      try mz.typeCheck(i, names, context, .pi(.nat) { k in mVal.apply(.succ(k)).apply(.fZero(k)) })

      // FIXME: double check this one with the Haskell source too
      try ms.typeCheck(
        i,
        names,
        context,
        .pi(.nat) { k in
          .pi(.fin(k)) { fk in
            .pi(mVal.apply(k).apply(fk)) { _ in
              mVal.apply(.succ(k)).apply(.fSucc(k, fk))
            }
          }
        }
      )

      try f.typeCheck(i, names, context, .fin(nVal))
      let fVal = f.eval(names, [])

      return mVal.apply(nVal).apply(fVal)

    case let term:
      throw PieError.noTypeMatch(term)
    }
  }
}
