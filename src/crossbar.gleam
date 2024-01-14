import gleam/io
import gleam/list.{append}
import gleam/dynamic

pub type Rule {
  Required
  MinLength(Int)
  MaxLength(Int)
  EqString(name: String, value: String)
  EqInt(name: String, value: Int)
  EqFloat(name: String, value: Float)
  EqBool(name: String, value: Bool)
  NotEqString(name: String, value: String)
  NotEqFloat(name: String, value: Float)
  NotEqInt(name: String, value: Int)
  NotEqBool(name: String, value: Bool)
}

// `a` is a phantom type to make sure that the field is of the same type as the value
pub opaque type Field(a) {
  IntField(name: String, value: Int, rules: List(Rule))
  FloatField(name: String, value: Float, rules: List(Rule))
  StringField(name: String, value: String, rules: List(Rule))
  BoolField(name: String, value: Bool, rules: List(Rule))
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

fn append_rule(field: Field(a), rule: Rule) -> Field(a) {
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

pub fn eq(field: Field(a), name: String, value: a) -> Field(a) {
  case field {
    IntField(_, _, _) ->
      case cast(value, dynamic.int) {
        Ok(v) -> append_rule(field, EqInt(name, v))
        Error(_) -> field
      }
    StringField(_, _, _) ->
      case cast(value, dynamic.string) {
        Ok(v) -> append_rule(field, EqString(name, v))
        Error(_) -> field
      }
    FloatField(_, _, _) ->
      case cast(value, dynamic.float) {
        Ok(v) -> append_rule(field, EqFloat(name, v))
        Error(_) -> field
      }
    BoolField(_, _, _) ->
      case cast(value, dynamic.bool) {
        Ok(v) -> append_rule(field, EqBool(name, v))
        Error(_) -> field
      }
  }
}

pub fn main() {
  io.println("Hello from crossbar!")

  6
  |> int("age")
  |> required
  |> eq("age", 4)
  |> io.debug
}
