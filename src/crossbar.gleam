import gleam/io
import gleam/list.{append}
import gleam/dynamic

// `a` is a type that is not used in the struct, but is used to make sure that the struct is of the same type as the value
pub type Rule(a) {
  Required
  MinLength(Int)
  MaxLength(Int)
  Eq(name: String, value: a)
  // EqString(name: String, value: String)
  // EqInt(name: String, value: a)
  // EqFloat(name: String, value: Float)
  // EqBool(name: String, value: Bool)
  // NotEqString(name: String, value: String)
  // NotEqFloat(name: String, value: Float)
  // NotEqInt(name: String, value: Int)
  // NotEqBool(name: String, value: Bool)
}

// `a` is a phantom type to make sure that the field is of the same type as the value
pub opaque type Field(a) {
  IntField(name: String, value: Int, rules: List(Rule(a)))
  FloatField(name: String, value: Float, rules: List(Rule(a)))
  StringField(name: String, value: String, rules: List(Rule(a)))
  BoolField(name: String, value: Bool, rules: List(Rule(a)))
}

// Instead of (name, value), I have chosen to use (value, name) to make it easier to pipe
pub fn int(value: Int, name: String) -> Field(Int) {
  IntField(name, value, [])
}

pub fn string(value: String, name: String) -> Field(Int) {
  StringField(name, value, [])
}

pub fn bool(value: Bool, name: String) -> Field(Int) {
  BoolField(name, value, [])
}

pub fn float(value: Float, name: String) -> Field(Int) {
  FloatField(name, value, [])
}

fn append_rule(field: Field(a), rule: Rule(a)) -> Field(a) {
  case field {
    IntField(name, value, rules) -> IntField(name, value, append(rules, [rule]))
    FloatField(name, value, rules) ->
      FloatField(name, value, append(rules, [rule]))
    StringField(name, value, rules) ->
      StringField(name, value, append(rules, [rule]))
    BoolField(name, value, rules) ->
      BoolField(name, value, append(rules, [rule]))
  }
}

pub fn required(field: Field(_)) -> Field(_) {
  append_rule(field, Required)
}

pub fn min_length(field: Field(_), length: Int) -> Field(_) {
  append_rule(field, MinLength(length))
}

pub fn max_length(field: Field(_), length: Int) -> Field(_) {
  append_rule(field, MaxLength(length))
}

fn cast(from: b, to: dynamic.Decoder(a)) -> Result(a, List(dynamic.DecodeError)) {
  dynamic.from(from)
  |> to
  |> fn(x) {
    case x {
      Ok(v) -> Ok(v)
      Error(e) -> Error(e)
    }
  }
}

fn cast_int(from: b) -> Int {
  case cast(from, dynamic.int) {
    Ok(v) -> v
    Error(_) -> 0
  }
}

pub fn eq(field: Field(a), name: String, value: a) -> Field(a) {
  append_rule(field, Eq(name, value))
}

fn tst(field: Field(a), value: a) {
  case field {
    IntField(_, v, _) -> v + cast_int(value)
    _ -> 0
  }
}

pub fn main() {
  io.println("Hello from crossbar!")

  6
  |> int("age")
  |> required
  |> eq("age", 5)
  |> tst(5)
  |> io.debug
}
