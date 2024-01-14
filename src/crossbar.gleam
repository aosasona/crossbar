import gleam/io
import gleam/list.{append}
import gleam/regex.{type Regex}

pub opaque type Rule(a) {
  Required
  MinLength(Int)
  MaxLength(Int)
  Eq(name: String, value: a)
  NotEq(name: String, value: a)
  UncompiledRegex(regex: String, error: String)
  Regex(regex: Regex, error: String)
  ValidatorFunction(validator: fn(a) -> Bool, error: String)
}

pub opaque type Field(a) {
  IntField(name: String, value: Int, rules: List(Rule(a)))
  FloatField(name: String, value: Float, rules: List(Rule(a)))
  StringField(name: String, value: String, rules: List(Rule(a)))
  BoolField(name: String, value: Bool, rules: List(Rule(a)))
}

pub fn int(name name: String, value value: Int) -> Field(Int) {
  IntField(name, value, [])
}

pub fn string(name name: String, value value: String) -> Field(String) {
  StringField(name, value, [])
}

pub fn bool(name name: String, value value: Bool) -> Field(Bool) {
  BoolField(name, value, [])
}

pub fn float(name name: String, value value: Float) -> Field(Float) {
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

pub fn required(field field: Field(_)) -> Field(_) {
  append_rule(field, Required)
}

pub fn min_length(field field: Field(_), length length: Int) -> Field(_) {
  append_rule(field, MinLength(length))
}

pub fn max_length(field field: Field(_), length length: Int) -> Field(_) {
  append_rule(field, MaxLength(length))
}

pub fn eq(field field: Field(a), name name: String, value value: a) -> Field(a) {
  append_rule(field, Eq(name, value))
}

pub fn not_eq(
  field field: Field(a),
  name name: String,
  value value: a,
) -> Field(a) {
  append_rule(field, NotEq(name, value))
}

pub fn with_validator(
  field field: Field(a),
  func func: fn(a) -> Bool,
  error_message error: String,
) -> Field(a) {
  append_rule(field, ValidatorFunction(func, error))
}

pub fn regex(
  field field: Field(a),
  regex regex: Regex,
  error_message error: String,
) -> Field(a) {
  append_rule(field, Regex(regex, error))
}

pub fn uncompiled_regex(
  field field: Field(a),
  regex regex: String,
  error_message error: String,
) -> Field(a) {
  append_rule(field, UncompiledRegex(regex, error))
}

pub fn main() {
  10
  |> int("age", _)
  |> required
  |> eq("age", 5)
  |> not_eq("other age", 10)
  |> with_validator(fn(x) { x > 5 }, "must be greater than 5")
  |> io.debug
}
