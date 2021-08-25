//
//  Created by Max Desiatov on 23/08/2021.
//

enum Name: Hashable {
  case global(String)
  case local(Int)
  case quote(Int)
}

indirect enum CheckedTerm {
  case inferred(InferredTerm)
  case lambda(CheckedTerm)
  case zero
  case succ(CheckedTerm)
  case `nil`(CheckedTerm)
  case cons(CheckedTerm, CheckedTerm, CheckedTerm, CheckedTerm)
  case refl(CheckedTerm, CheckedTerm)
  case fZero(CheckedTerm)
  case fSucc(CheckedTerm, CheckedTerm)
}

indirect enum InferredTerm {
  case annotation(CheckedTerm, CheckedTerm)
  case star
  case pi(CheckedTerm, CheckedTerm)
  case bound(Int)
  case free(Name)
  case dollarOperator(InferredTerm, CheckedTerm)
  case nat
  case natElim(CheckedTerm, CheckedTerm, CheckedTerm, CheckedTerm)
  case vec(CheckedTerm, CheckedTerm)
  case vecElim(CheckedTerm, CheckedTerm, CheckedTerm, CheckedTerm, CheckedTerm, CheckedTerm)
  case eq(CheckedTerm, CheckedTerm, CheckedTerm)
  case eqElim(CheckedTerm, CheckedTerm, CheckedTerm, CheckedTerm, CheckedTerm, CheckedTerm)
  case fin(CheckedTerm)
  case finElim(CheckedTerm, CheckedTerm, CheckedTerm, CheckedTerm, CheckedTerm)
}

indirect enum Value {
  case lambda((Value) -> Value)
  case star
  case pi(Value, (Value) -> Value)
  case neutral(Neutral)
  case nat
  case zero
  case succ(Value)
  case `nil`(Value)
  case cons(Value, Value, Value, Value)
  case vec(Value, Value)
  case eq(Value, Value, Value)
  case refl(Value, Value)
  case fZero(Value)
  case fSucc(Value, Value)
  case fin(Value)

  func apply(_ value: Value) -> Value {
    switch self {
    case let .lambda(f): return f(value)
    case let .neutral(n): return .neutral(.app(n, value))
    default: fatalError()
    }
  }

  static func free(_ name: Name) -> Value {
    .neutral(.free(name))
  }
}

indirect enum Neutral {
  case free(Name)
  case app(Neutral, Value)
  case natElim(Value, Value, Value, Neutral)
  case vecElim(Value, Value, Value, Value, Value, Neutral)
  case eqElim(Value, Value, Value, Value, Value, Neutral)
  case finElim(Value, Value, Value, Value, Neutral)
}

typealias Env = [Value]
typealias Type = Value
typealias Context = [Name: Type]
typealias NameEnv = [Name: Value]
