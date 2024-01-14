import gleam/io
import gleam/list.{append}

pub type Rule(a) {
  Required
  MinLength(Int)
  MaxLength(Int)
  Eq(name: String, value: a)
  NotEq(name: String, value: a)
}

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

pub fn string(value: String, name: String) -> Field(String) {
  StringField(name, value, [])
}

pub fn bool(value: Bool, name: String) -> Field(Bool) {
  BoolField(name, value, [])
}

pub fn float(value: Float, name: String) -> Field(Float) {
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

pub fn eq(field: Field(a), name: String, value: a) -> Field(a) {
  append_rule(field, Eq(name, value))
}

pub fn main() {
  int(6, "age")
  |> required
  |> eq("age", 5)
  |> io.debug
}
