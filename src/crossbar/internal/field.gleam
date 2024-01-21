import crossbar/internal/cast
import gleam/bit_array
import gleam/bool
import gleam/float
import gleam/order
import gleam/int
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
}

pub fn validate_required(field: Field(_)) -> Bool {
  case field {
    IntField(_, value, _) -> value != 0
    FloatField(_, value, _) -> value != 0.0
    StringField(_, value, _) -> string.trim(value) != ""
    BoolField(_, _, _) -> True
  }
}

pub fn validate_min_value(field: Field(_), min: Float) -> Bool {
  let value = case field {
    IntField(_, value, _) -> int.to_float(value)
    FloatField(_, value, _) -> value
    StringField(_, value, _) -> string_to_float_byte_size(value)
    BoolField(_, value, _) -> bool_to_float(value)
  }

  float.min(min, value) == min
}

pub fn validate_max_value(field: Field(_), max: Float) -> Bool {
  let value = case field {
    IntField(_, value, _) -> int.to_float(value)
    FloatField(_, value, _) -> value
    StringField(_, value, _) -> string_to_float_byte_size(value)
    BoolField(_, value, _) -> bool_to_float(value)
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
    }
    |> string.trim
    |> string.length

  field_length >= min_length
}

pub fn validate_max_length(field: Field(_), max_length: Int) -> Bool {
  let field_length =
    case field {
      IntField(_, value, _) -> int.to_string(value)
      FloatField(_, value, _) -> float.to_string(value)
      StringField(_, value, _) -> value
      BoolField(_, value, _) -> bool.to_string(value)
    }
    |> string.trim
    |> string.length

  field_length <= max_length
}

pub fn validate_eq(field: Field(a), to other_value: a) -> Bool {
  case field {
    IntField(_, value, _) ->
      int.compare(value, cast.int(other_value)) == order.Eq
    FloatField(_, value, _) ->
      float.compare(value, cast.float(other_value)) == order.Eq
    StringField(_, value, _) ->
      string.compare(value, cast.string(other_value)) == order.Eq
    BoolField(_, value, _) ->
      bool.compare(value, cast.bool(other_value)) == order.Eq
  }
}

pub fn validate_not_eq(field: Field(a), to other_value: a) -> Bool {
  case field {
    IntField(_, value, _) ->
      int.compare(value, cast.int(other_value)) != order.Eq
    FloatField(_, value, _) ->
      float.compare(value, cast.float(other_value)) != order.Eq
    StringField(_, value, _) ->
      string.compare(value, cast.string(other_value)) != order.Eq
    BoolField(_, value, _) ->
      bool.compare(value, cast.bool(other_value)) != order.Eq
  }
}

pub fn validate_uncompiled_regex(
  field: Field(_),
  name: String,
  regex: String,
  error: String,
) -> Bool {
  case field {
    IntField(_, _, _) -> todo
    FloatField(_, _, _) -> todo
    StringField(_, _, _) -> todo
    BoolField(_, _, _) -> todo
  }
}

pub fn validate_regex(
  field: Field(_),
  name: String,
  regex: Regex,
  error: String,
) -> Bool {
  case field {
    IntField(_, _, _) -> todo
    FloatField(_, _, _) -> todo
    StringField(_, _, _) -> todo
    BoolField(_, _, _) -> todo
  }
}

pub fn use_validator_function(
  field: Field(_),
  name: String,
  validator: fn(a) -> Bool,
  error: String,
) -> Bool {
  case field {
    IntField(_, _, _) -> todo
    FloatField(_, _, _) -> todo
    StringField(_, _, _) -> todo
    BoolField(_, _, _) -> todo
  }
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
