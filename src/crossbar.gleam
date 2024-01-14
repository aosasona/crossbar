import gleam/io
import gleam/list.{append}
import gleam/regex.{type Regex}
import gleam/bool

pub opaque type Rule(a) {
  Required
  MinLength(Int)
  MaxLength(Int)
  Eq(name: String, value: a)
  NotEq(name: String, value: a)
  UncompiledRegex(name: String, regex: String, error: String)
  Regex(name: String, regex: Regex, error: String)
  ValidatorFunction(name: String, validator: fn(a) -> Bool, error: String)
}

pub opaque type Field(a) {
  IntField(name: String, value: Int, rules: List(Rule(a)))
  FloatField(name: String, value: Float, rules: List(Rule(a)))
  StringField(name: String, value: String, rules: List(Rule(a)))
  BoolField(name: String, value: Bool, rules: List(Rule(a)))
}

pub type CrossBarError {
  FailedRule(rule: String, error: String)
}

pub type ValidationResult(a) =
  Result(Field(a), List(CrossBarError))

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

fn rule_to_string(rule: Rule(_)) -> String {
  case rule {
    Required -> "required"
    MinLength(_) -> "min_length"
    MaxLength(_) -> "max_length"
    Eq(_, _) -> "eq"
    NotEq(_, _) -> "not_eq"
    UncompiledRegex(name, _, _) -> {
      use <- bool.guard(when: name == "", return: "uncompiled_regex")
      name
    }

    Regex(name, _, _) -> {
      use <- bool.guard(when: name == "", return: "regex")
      name
    }
    ValidatorFunction(name, _, _) -> {
      use <- bool.guard(when: name == "", return: "validator_function")
      name
    }
  }
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
  rule_name name: String,
  validator func: fn(a) -> Bool,
  error error: String,
) -> Field(a) {
  append_rule(field, ValidatorFunction(name, func, error))
}

pub fn regex(
  field field: Field(a),
  rule_name name: String,
  regex regex: Regex,
  error_message error: String,
) -> Field(a) {
  append_rule(field, Regex(name, regex, error))
}

pub fn uncompiled_regex(
  field field: Field(a),
  rule_name name: String,
  regex regex: String,
  error_message error: String,
) -> Field(a) {
  append_rule(field, UncompiledRegex(name, regex, error))
}

fn validate_required(field: Field(a)) -> CrossBarError {
  todo
}

pub fn validate(field: Field(a)) -> ValidationResult(a) {
  todo
}

fn validate_field(
  field: Field(a),
  rules: List(Rule(a)),
  errors: List(CrossBarError),
) -> List(CrossBarError) {
  todo
}

pub fn main() {
  10
  |> int("age", _)
  |> required
  |> eq("age", 5)
  |> not_eq("other age", 10)
  |> with_validator(
    rule_name: "greater_than_5",
    validator: fn(x) { x > 5 },
    error: "must be greater than 5",
  )
  |> io.debug
}
