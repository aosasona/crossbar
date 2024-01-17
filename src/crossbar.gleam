import crossbar/internal/cast
import gleam/bool
import gleam/float
import gleam/int
import gleam/list.{append}
import gleam/option.{type Option, None, Some}
import gleam/regex.{type Regex}
import gleam/string

pub opaque type Rule(a) {
  Required
  MinSize(Float)
  MaxSize(Float)
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
  OptionalIntField(name: String, value: Option(Int), rules: List(Rule(a)))
  OptionalFloatField(name: String, value: Option(Float), rules: List(Rule(a)))
  OptionalStringField(name: String, value: Option(String), rules: List(Rule(a)))
  OptionalBoolField(name: String, value: Option(Bool), rules: List(Rule(a)))
}

pub type CrossBarError {
  FailedRule(rule: String, error: String)
}

pub type ValidationResult(a) =
  Result(Field(a), List(CrossBarError))

/// Creates a new `Int` field with the given name and value
pub fn int(name name: String, value value: Int) -> Field(Int) {
  IntField(name, value, [])
}

/// Creates a new `Float` field with the given name and value
pub fn float(name name: String, value value: Float) -> Field(Float) {
  FloatField(name, value, [])
}

/// Creates a new `String` field with the given name and value
pub fn string(name name: String, value value: String) -> Field(String) {
  StringField(name, value, [])
}

/// Creates a new `Bool` field with the given name and value
pub fn bool(name name: String, value value: Bool) -> Field(Bool) {
  BoolField(name, value, [])
}

/// Creates a new `Option(Int)` field with the given name and value
pub fn optional_int(name name: String, value value: Option(Int)) -> Field(Int) {
  OptionalIntField(name, value, [])
}

/// Creates a new `Option(Float)` field with the given name and value
pub fn optional_float(
  name name: String,
  value value: Option(Float),
) -> Field(Float) {
  OptionalFloatField(name, value, [])
}

/// Creates a new `Option(String)` field with the given name and value
pub fn optional_string(
  name name: String,
  value value: Option(String),
) -> Field(String) {
  OptionalStringField(name, value, [])
}

/// Creates a new `Option(Bool)` field with the given name and value
pub fn optional_bool(
  name name: String,
  value value: Option(Bool),
) -> Field(Bool) {
  OptionalBoolField(name, value, [])
}

/// Returns the string representation of a rule - this is internally used for error states
pub fn rule_to_string(rule: Rule(_)) -> String {
  case rule {
    Required -> "required"
    MinSize(_) -> "min_size"
    MaxSize(_) -> "max_size"
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

pub fn get_error_message(rule: Rule(_)) -> String {
  case rule {
    Required -> "is required"
    MinSize(v) -> "must be at least " <> float.to_string(v)
    MaxSize(v) -> "must not be greater than " <> float.to_string(v)
    MinLength(v) -> "must be at least " <> int.to_string(v) <> " characters"
    MaxLength(v) ->
      "must not be longer than " <> int.to_string(v) <> " characters"
    Eq(name, value) ->
      "must be equal to " <> extract_last_error_part(name, value)
    NotEq(name, value) ->
      "must not be equal to " <> extract_last_error_part(name, value)
    UncompiledRegex(_, regex, error) -> {
      use <- bool.guard(when: error != "", return: error)
      "must match the following pattern: " <> regex
    }
    Regex(_, _, error) -> error
    ValidatorFunction(_, _, error) -> error
  }
}

fn extract_last_error_part(name: String, value: a) -> String {
  use <- bool.guard(when: name == "", return: cast.to_string(value))
  name <> " (" <> cast.to_string(value) <> ")"
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

    OptionalIntField(name, value, rules) ->
      OptionalIntField(name, value, append(rules, [rule]))

    OptionalFloatField(name, value, rules) ->
      OptionalFloatField(name, value, append(rules, [rule]))

    OptionalStringField(name, value, rules) ->
      OptionalStringField(name, value, append(rules, [rule]))

    OptionalBoolField(name, value, rules) ->
      OptionalBoolField(name, value, append(rules, [rule]))
  }
}

/// The required rule makes sure that the field is not empty, this is the expected behaviour in the following cases:
/// > `Int`: **0** is considered empty
/// > `Float`: **0.0** is also considered empty
/// > `String`: "" (or anything that trims down to that) is considered empty
/// > `Bool`: this isn't really a thing, but it's here for completeness sake and it will always return true, because a bool is never empty (unless it is wrapped in an option)
/// > `Option`: this is considered empty if it is `None`
pub fn required(field field: Field(_)) -> Field(_) {
  append_rule(field, Required)
}

/// The `min_size` rule makes sure that the field is at least the given (byte where it applies) size.
/// > Strings are counted in bytes (as bit arrays), `Int`s and `Float`s are evaluated directly, `Bool`s are treated as their binary equivalent (0 or 1).
pub fn min_size(field field: Field(_), size size: Float) -> Field(_) {
  append_rule(field, MinSize(size))
}

/// The `max_size` rule makes sure that the field is at most the given (byte) size.
/// > Strings are counted in bytes (as bit arrays), `Int`s and `Float`s are evaluated directly, `Bool`s are treated as their binary equivalent (0 or 1).
pub fn max_size(field field: Field(_), size size: Float) -> Field(_) {
  append_rule(field, MaxSize(size))
}

/// The `min_length` rule makes sure that the field is at least the given length, this is the expected behaviour in the following cases:
/// > `Int`: the length of the string representation of the number, this isn't very useful to you, but it's here for completeness sake. You probably want to use `min_size` instead.
/// > `Float`: the length of the string representation of the number, this isn't very useful to you, but it's here for completeness sake. You probably want to use `min_size` instead.
/// > `String`: the length of the string is evaluated directly
/// > `Bool`: this also isn't very useful to you, but it's here for completeness sake.
/// > `Option`: this is considered empty if it is `None`, the Some values are evaluated as their respective types.
pub fn min_length(field field: Field(_), length length: Int) -> Field(_) {
  append_rule(field, MinLength(length))
}

/// The `max_length` rule makes sure that the field is at most the given length, this is the expected behaviour in the following cases:
/// > `Int`: the length of the string representation of the number, this isn't very useful to you, but it's here for completeness sake. You probably want to use `max_size` instead.
/// > `Float`: the length of the string representation of the number, this also isn't very useful to you, but it's here for completeness sake. You probably want to use `max_size` instead.
/// > `String`: the length of the string is evaluated directly
/// > `Bool`: this also isn't very useful to you, but it's here for completeness sake.
/// > `Option`: this is considered empty if it is `None`, the Some values are evaluated as their respective types.
pub fn max_length(field field: Field(_), length length: Int) -> Field(_) {
  append_rule(field, MaxLength(length))
}

/// The `eq` rule makes sure that the field is equal to the given value, strings are compared securely bit by bit, so this is safe to use for passwords, other types are compared directly.
pub fn eq(
  field field: Field(a),
  name name: String,
  value value: a,
) -> Field(a) {
  append_rule(field, Eq(name, value))
}

/// The `not_eq` rule makes sure that the field is not equal to the given value, strings are compared securely bit by bit, so this is safe to use for passwords, other types are compared directly.
pub fn not_eq(
  field field: Field(a),
  name name: String,
  value value: a,
) -> Field(a) {
  append_rule(field, NotEq(name, value))
}

/// The `with_validator` rule makes sure that the field passes the given validator function, the function should return a `Bool` and take the field value as its only argument.
///
/// ## Example
///
/// ```gleam
/// let validator = fn(x) { x > 5 }
/// let error = "must be greater than 5"
///
/// int("age", 6)
/// |> with_validator("greater_than_5", validator, error)
/// ```
pub fn with_validator(
  field field: Field(a),
  rule_name name: String,
  validator func: fn(a) -> Bool,
  error error: String,
) -> Field(a) {
  append_rule(field, ValidatorFunction(name, func, error))
}

/// The `regex` rule makes sure that the field matches the given regex, you are required to compile the regex yourself, if you want to use an uncompiled regex, use the `uncompiled_regex` rule instead.
///
/// ## Example
///
/// ```gleam
/// import gleam/regex
///
/// let options = Options(case_insensitive: False, multi_line: True)
/// let assert Ok(re) = compile("^[0-9]", with: options)
///
/// string("name", "1john")
/// |> regex("starts_with_number", re,  "must start with a number")
/// ```
pub fn regex(
  field field: Field(a),
  rule_name name: String,
  regex regex: Regex,
  error_message error: String,
) -> Field(a) {
  append_rule(field, Regex(name, regex, error))
}

/// The `uncompiled_regex` rule takes a string representation of a regex and compiles it for you, if you want to use a pre-compiled regex, use the `regex` rule instead.
/// The main difference is that this will not let you pass in additional options, so if you need those, you should use the `regex` rule instead.
///
/// ## Example
///
/// ```gleam
/// string("name", "1john")
/// |> uncompiled_regex("starts_with_number", "^[0-9]",  "must start with a number")
/// ```
pub fn uncompiled_regex(
  field field: Field(a),
  rule_name name: String,
  regex regex: String,
  error_message error: String,
) -> Field(a) {
  append_rule(field, UncompiledRegex(name, regex, error))
}

fn validate_required(field: Field(a)) -> Bool {
  case field {
    IntField(_, value, _) -> value != 0
    FloatField(_, value, _) -> value != 0.0
    StringField(_, value, _) -> string.trim(value) != ""
    BoolField(_, _, _) -> True
    OptionalIntField(_, value, _) ->
      option.is_some(value) && option.unwrap(value, or: 0) != 0
    OptionalFloatField(_, value, _) ->
      option.is_some(value) && option.unwrap(value, or: 0.0) != 0.0
    OptionalStringField(_, value, _) ->
      case value {
        Some(v) -> string.trim(v) != ""
        None -> False
      }
    OptionalBoolField(_, value, _) -> option.is_some(value)
  }
}

pub fn validate(field: Field(a)) -> ValidationResult(a) {
  let validation_result = validate_field(field, field.rules, [])

  case validation_result {
    [] -> Ok(field)
    _ -> Error(validation_result)
  }
}

fn validate_field(
  field: Field(a),
  rules: List(Rule(a)),
  errors: List(CrossBarError),
) -> List(CrossBarError) {
  case rules {
    [] -> errors
    [rule, ..other_rules] -> {
      let validation_result = case rule {
        Required -> validate_required(field)
        _ -> todo as "other rules have not been implemented yet"
      }

      use <- bool.guard(when: validation_result, return: errors)
      let errors =
        append(errors, [
          FailedRule(rule: rule_to_string(rule), error: get_error_message(rule)),
        ])

      validate_field(field, other_rules, errors)
    }
  }
}
