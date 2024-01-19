import gleam/bit_array
import gleam/bool
import gleam/float
import gleam/int
import gleam/option.{type Option, None, Some}
import gleam/regex.{type Regex}
import gleam/string

// Avoid using these types directly, they are not opaque because the associated functions are in the entry file
pub type Rule(a) {
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

// Avoid using these types directly, they are not opaque because the associated functions are in the entry file
pub type Field(a) {
  IntField(name: String, value: Int, rules: List(Rule(a)))
  FloatField(name: String, value: Float, rules: List(Rule(a)))
  StringField(name: String, value: String, rules: List(Rule(a)))
  BoolField(name: String, value: Bool, rules: List(Rule(a)))
  OptionalIntField(name: String, value: Option(Int), rules: List(Rule(a)))
  OptionalFloatField(name: String, value: Option(Float), rules: List(Rule(a)))
  OptionalStringField(name: String, value: Option(String), rules: List(Rule(a)))
  OptionalBoolField(name: String, value: Option(Bool), rules: List(Rule(a)))
}

pub fn validate_required(field: Field(_)) -> Bool {
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

pub fn validate_min_size(field: Field(_), min: Float) -> Bool {
  let value = case field {
    IntField(_, value, _) -> int.to_float(value)
    FloatField(_, value, _) -> value
    StringField(_, value, _) -> string_to_float_byte_size(value)
    BoolField(_, value, _) -> bool_to_float(value)
    OptionalIntField(_, value, _) -> int.to_float(option.unwrap(value, or: 0))
    OptionalFloatField(_, value, _) -> option.unwrap(value, or: 0.0)
    OptionalStringField(_, value, _) ->
      option.unwrap(value, or: "")
      |> string_to_float_byte_size
    OptionalBoolField(_, value, _) ->
      option.unwrap(value, or: False)
      |> bool_to_float
  }

  float.min(min, value) == min
}

pub fn validate_max_size(field: Field(_), max: Float) -> Bool {
  let value = case field {
    IntField(_, value, _) -> int.to_float(value)
    FloatField(_, value, _) -> value
    StringField(_, value, _) -> string_to_float_byte_size(value)
    BoolField(_, value, _) -> bool_to_float(value)
    OptionalIntField(_, value, _) -> int.to_float(option.unwrap(value, or: 0))
    OptionalFloatField(_, value, _) -> option.unwrap(value, or: 0.0)
    OptionalStringField(_, value, _) ->
      option.unwrap(value, or: "")
      |> string_to_float_byte_size
    OptionalBoolField(_, value, _) ->
      option.unwrap(value, or: False)
      |> bool_to_float
  }

  float.max(max, value) == max
}

pub fn validate_min_length(field: Field(_), min_length: Int) -> Bool {
  let field_length =
    case field {
      IntField(_, value, _) -> int.to_string(value)
      FloatField(_, value, _) -> float.to_string(value)
      StringField(_, value, _) -> value
      BoolField(_, value, _) -> bool.to_string(value)
      OptionalIntField(_, value, _) ->
        case value {
          Some(v) -> int.to_string(v)
          None -> ""
        }
      OptionalFloatField(_, value, _) ->
        case value {
          Some(v) -> float.to_string(v)
          None -> ""
        }
      OptionalStringField(_, value, _) -> option.unwrap(value, or: "")
      OptionalBoolField(_, value, _) ->
        option.unwrap(value, or: False)
        |> bool.to_string
    }
    |> string.trim
    |> string.length

  field_length >= min_length
}

// TODO: test
pub fn validate_max_length(field: Field(_), max_length: Int) -> Bool {
  let field_length =
    case field {
      IntField(_, value, _) -> int.to_string(value)
      FloatField(_, value, _) -> float.to_string(value)
      StringField(_, value, _) -> value
      BoolField(_, value, _) -> bool.to_string(value)
      OptionalIntField(_, value, _) ->
        case value {
          Some(v) -> int.to_string(v)
          None -> ""
        }
      OptionalFloatField(_, value, _) ->
        case value {
          Some(v) -> float.to_string(v)
          None -> ""
        }
      OptionalStringField(_, value, _) -> option.unwrap(value, or: "")
      OptionalBoolField(_, value, _) ->
        option.unwrap(value, or: False)
        |> bool.to_string
    }
    |> string.trim
    |> string.length

  field_length <= max_length
}

fn string_to_float_byte_size(value: String) -> Float {
  value
  |> bit_array.from_string
  |> bit_array.byte_size
  |> int.to_float
}

fn bool_to_float(value: Bool) -> Float {
  case value {
    True -> 1.0
    False -> 0.0
  }
}
