import crossbar/internal/cast
import crossbar/internal/field.{
  type Field, type Rule, BoolField, Eq, FloatField, IntField, MaxLength, MaxSize,
  MinLength, MinSize, NotEq, Regex, Required, StringField, ValidatorFunction,
}
import gleam/bool
import gleam/float
import gleam/int
import gleam/json
import gleam/list.{append}
import gleam/regex

pub type JsonMode {
  /// Return errors as an array of error strings
  /// ```json
  /// ["is required", "must be at least 5 characters"]
  /// ```
  Array

  /// Return errors as an object with the rule name as the key and the error string as the value
  /// ```json
  /// { "required": "is required", "min_length": "must be at least 5 characters" }
  /// ```
  KeyValue
}

/// The `CrossBarError` type is used to represent errors that occur during validation.
pub type CrossBarError {
  FailedRule(name: String, rule: String, error: String)
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

/// Returns the string representation of a rule - this is internally used for error states
pub fn rule_to_string(rule: Rule(_)) -> String {
  case rule {
    Required -> "required"
    MinSize(_) -> "min_value"
    MaxSize(_) -> "max_value"
    MinLength(_) -> "min_length"
    MaxLength(_) -> "max_length"
    Eq(_, _) -> "eq"
    NotEq(_, _) -> "not_eq"
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

/// Get the default error message for a rule - this is internally used for error states
pub fn rule_to_error_string(rule: Rule(_)) -> String {
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
    Regex(_, _, error) -> error
    ValidatorFunction(_, _, error) -> error
  }
}

fn extract_last_error_part(name: String, value: a) -> String {
  let value_string = cast.to_string(value)
  use <- bool.guard(when: name == "", return: value_string)
  use <- bool.guard(when: value_string == "", return: name)

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
  }
}

fn int_rules_to_float_rules(rules: List(Rule(Int))) -> List(Rule(Float)) {
  rules
  |> list.map(fn(rule) {
    case rule {
      Required -> Required
      MinSize(v) -> MinSize(v)
      MaxSize(v) -> MaxSize(v)
      MinLength(v) -> MinLength(v)
      MaxLength(v) -> MaxLength(v)
      Eq(name, value) -> Eq(name, int.to_float(value))
      NotEq(name, value) -> NotEq(name, int.to_float(value))
      Regex(name, regex, error) -> Regex(name, regex, error)

      // Ideally, the type system will prevent this from happening, but just in case the user refuses to read the documentation for `to_float`, we'll handle it here
      ValidatorFunction(name, original_validator, error) ->
        ValidatorFunction(
          name,
          fn(v: Float) {
            v
            |> float.round
            |> original_validator
          },
          error,
        )
    }
  })
}

/// Convenient function to convert an `Int` to a `Float`, you should use this BEFORE applying any rules.
///
/// ## Example
///
/// ```gleam
/// int("age", 6)
/// |> to_float
/// |> min_value(5.0)
/// ```
///
pub fn to_float(field: Field(Int)) -> Field(Float) {
  let assert IntField(name, value, rules) = field

  value
  |> int.to_float
  |> FloatField(name, _, int_rules_to_float_rules(rules))
}

/// The required rule makes sure that the field is not empty, this is the expected behaviour in the following cases:
/// > `Int`: **0** is considered empty
///
/// > `Float`: **0.0** is also considered empty
///
/// > `String`: "" (or anything that trims down to that) is considered empty
///
/// > `Bool`: this isn't really a thing, but it's here for completeness sake and it will always return true, because a bool is never empty (unless it is wrapped in an option)
///
pub fn required(field field: Field(_)) -> Field(_) {
  append_rule(field, Required)
}

/// The `min_value` rule makes sure that the field is at least the given (byte where it applies) size.
/// > Strings are counted in bytes (as bit arrays), `Int`s and `Float`s are evaluated directly, `Bool`s are treated as their binary equivalent (0 or 1).
///
/// NOTE: This function has been momentarily restricted to `Float` fields, because it's not very useful for other types, open an issue if you ever find a use for it. There is also a `to_float` function to transform int fields to float fields (meant to be used before you add any rules)
pub fn min_value(field field: Field(Float), size size: Float) -> Field(_) {
  append_rule(field, MinSize(size))
}

/// The `max_value` rule makes sure that the field is at most the given (byte) size.
/// > Strings are counted in bytes (as bit arrays), `Int`s and `Float`s are evaluated directly, `Bool`s are treated as their binary equivalent (0 or 1).
///
/// NOTE: This function has been momentarily restricted to `Float` fields, because it's not very useful for other types, open an issue if you ever find a use for it. There is also a `to_float` function to transform int fields to float fields (meant to be used before you add any rules)
pub fn max_value(field field: Field(Float), size size: Float) -> Field(_) {
  append_rule(field, MaxSize(size))
}

/// The `min_length` rule makes sure that the field is at least the given length, this is the expected behaviour in the following cases:
/// > `Int`: the length of the string representation of the number, this isn't very useful to you, but it's here for completeness sake. You probably want to use `min_value` instead.
///
/// > `Float`: the length of the string representation of the number, this isn't very useful to you, but it's here for completeness sake. You probably want to use `min_value` instead.
///
/// > `String`: the length of the string is evaluated directly
///
/// > `Bool`: this also isn't very useful to you, but it's here for completeness sake.
///
/// NOTE: This function has been momentarily restricted to `String` fields, because it's not very useful for other types, open an issue if you ever find a use for it.
pub fn min_length(field field: Field(String), length length: Int) -> Field(_) {
  append_rule(field, MinLength(length))
}

/// The `max_length` rule makes sure that the field is at most the given length, this is the expected behaviour in the following cases:
/// > `Int`: the length of the string representation of the number, this isn't very useful to you, but it's here for completeness sake. You probably want to use `max_value` instead.
///
/// > `Float`: the length of the string representation of the number, this also isn't very useful to you, but it's here for completeness sake. You probably want to use `max_value` instead.
///
/// > `String`: the length of the string is evaluated directly
///
/// > `Bool`: this also isn't very useful to you, but it's here for completeness sake.
///
/// NOTE: This function has been momentarily restricted to `String` fields, because it's not very useful for other types, open an issue if you ever find a use for it.
pub fn max_length(field field: Field(String), length length: Int) -> Field(_) {
  append_rule(field, MaxLength(length))
}

/// The `eq` rule makes sure that the field is equal to the given value, strings are NOT compared securely, so this is NOT safe to use for passwords, all types are compared directly.
pub fn eq(field field: Field(a), name name: String, value value: a) -> Field(a) {
  append_rule(field, Eq(name, value))
}

/// The `not_eq` rule makes sure that the field is not equal to the given value, strings are NOT compared securely, so this is NOT safe to use for passwords, other types are compared directly.
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
  regex regex: regex.Regex,
  error_message error: String,
) -> Field(a) {
  append_rule(field, Regex(name, regex, error))
}

/// Run the validation on the given field, returns an `Ok` if the validation was successful, otherwise returns an `Error` with a list of errors.
///
/// ## Example
///
/// ```gleam
/// let field = int("age", 6)
/// |> to_float
/// |> min_value(5.0)
/// |> validate
/// ```
pub fn validate(field: Field(a)) -> ValidationResult(a) {
  let validation_result = validate_field(field, field.rules, [])

  case validation_result {
    [] -> Ok(field)
    _ -> Error(validation_result)
  }
}

/// Validate a list of fields, returns a list of tuples with the field name and a list of errors - unfortunately, currently, only supports validating fields of the same type.
pub fn validate_many(
  fields: List(Field(_)),
) -> List(#(String, List(CrossBarError))) {
  fields
  |> list.map(fn(field) {
    let errors = case validate(field) {
      Ok(_) -> []
      Error(errors) -> errors
    }

    #(field.name, errors)
  })
}

/// Useful for extracting the errors as a list of tuples (#(rule_name, error_as_string)), this is useful for returning errors as JSON.
pub fn extract_errors(result: ValidationResult(a)) -> List(#(String, String)) {
  let errors = case result {
    Ok(_) -> []
    Error(errors) -> errors
  }

  list.map(errors, fn(error) {
    case error {
      FailedRule(_, rule, error) -> #(rule, error)
    }
  })
}

fn extract_field_name(result: ValidationResult(a)) -> String {
  case result {
    Ok(field) -> field.name
    Error(errors) -> {
      case errors {
        [FailedRule(name, _, _), ..] -> name
        [] -> ""
      }
    }
  }
}

/// Transform a field into a tuple that can be used to generate JSON, this is useful for returning errors as JSON. The `field_name` argument is optional, if you don't provide it, the field name will be extracted from the validation result if it can be (which is usually the case).
///
/// ## Example
///
/// ```gleam
/// let first_name =
///   string("first_name", "")
///   |> required
///   |> min_length(3)
///   |> validate
///   |> to_serializable("", KeyValue)
///
/// let last_name =
///   string("last_name", "Smith")
///   |> required
///   |> min_length(1)
///   |> max_length(3)
///   |> validate
///   |> to_serializable("renamed_last_field", KeyValue)
///
/// json.object([first_name, last_name])
/// |> json.to_string
/// |> io.println
/// ```
///
/// The above example will produce the following JSON:
///
/// ```json
/// {
///   "first_name": {
///     "required": "is required",
///     "min_length": "must be at least 3 characters"
///   },
///   "renamed_last_name": {
///     "max_length": "must not be longer than 3 characters"
///   }
/// }
/// ```
pub fn to_serializable(
  result validation_result: ValidationResult(a),
  field_name field_name: String,
  mode mode: JsonMode,
) -> #(String, json.Json) {
  let name = case field_name {
    "" -> extract_field_name(validation_result)
    _ -> field_name
  }

  let errors =
    validation_result
    |> extract_errors

  use <- bool.guard(when: errors == [], return: #(name, json.null()))

  let json_value = case mode {
    Array -> {
      let errors_list = list.map(errors, fn(e) { e.1 })
      json.array(errors_list, json.string)
    }
    KeyValue ->
      json.object(list.map(errors, fn(e) { #(e.0, json.string(e.1)) }))
  }

  #(name, json_value)
}

/// Validate a list of fields and transform them into a list of tuples that can be used to generate JSON, this is useful for returning errors as JSON.
///
/// ## Example
///
/// ```gleam
/// let first_name =
///   string("first_name", "")
///   |> required
///   |> min_length(3)
///
/// let last_name =
///   string("last_name", "Smith")
///   |> required
///   |> min_length(1)
///   |> max_length(3)
///
/// to_serializable_list([first_name, last_name], KeyValue)
/// |> serializables_to_string
/// |> io.println
/// ```
///
/// The above example will produce the following JSON:
///
/// ```json
/// {
///   "first_name": {
///     "required": "is required",
///     "min_length": "must be at least 3 characters"
///   },
///   "last_name": {
///     "max_length": "must not be longer than 3 characters"
///   }
/// }
/// ```
pub fn to_serializable_list(
  fields: List(Field(_)),
  mode: JsonMode,
) -> List(#(String, json.Json)) {
  fields
  |> list.map(fn(field) {
    field
    |> validate
    |> to_serializable(field.name, mode)
  })
}

/// Utility function to convert a list of serializable tuples into a JSON string.
pub fn serializables_to_string(
  serializables: List(#(String, json.Json)),
) -> String {
  serializables
  |> json.object
  |> json.to_string
}

/// Useful for checking if the result of `to_serializable` collected into a list has any errors, this is useful for checking if any of the fields failed validation.
///
/// ## Example
///
/// ```gleam
/// let first_name =
///   string("first_name", "John")
///   |> required
///   |> min_length(3)
///   |> to_serializable(KeyValue)
///
/// let last_name =
///   string("last_name", "Smith")
///   |> required
///   |> min_length(1)
///   |> max_length(10)
///   |> to_serializable(KeyValue)
///
/// let errors = [first_name, last_name]
///
/// case has_errors(errors) {
///   True -> io.println("There are errors")
///   False -> io.println("There are no errors")
/// }
/// ```
pub fn has_errors(json_errors: List(#(String, json.Json))) -> Bool {
  json_errors
  |> list.map(fn(e) { e.1 })
  |> list.any(fn(e) { e != json.null() })
}

fn validate_field(
  field: Field(a),
  rules: List(Rule(a)),
  errors: List(CrossBarError),
) -> List(CrossBarError) {
  case rules {
    [rule, ..other_rules] -> {
      let validation_result = case rule {
        Required -> field.validate_required(field)
        MinSize(size) -> field.validate_min_value(field, size)
        MaxSize(size) -> field.validate_max_value(field, size)
        MinLength(length) -> field.validate_min_length(field, length)
        MaxLength(length) -> field.validate_max_length(field, length)
        Eq(_, value) -> field.validate_eq(field, value)
        NotEq(_, value) -> field.validate_not_eq(field, value)
        Regex(_, regex, _) -> field.validate_regex(field, regex)
        ValidatorFunction(_, func, _) ->
          field.use_validator_function(field, func)
      }

      let new_errors = {
        use <- bool.guard(when: validation_result, return: errors)

        errors
        |> append([
          FailedRule(
            name: field.name,
            rule: rule_to_string(rule),
            error: rule_to_error_string(rule),
          ),
        ])
      }

      validate_field(field, other_rules, new_errors)
    }
    [] -> errors
  }
}
