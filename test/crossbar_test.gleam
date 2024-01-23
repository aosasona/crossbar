import gleam/list
import gleeunit
import gleeunit/should
import gleam/regex
import gleam/string
import crossbar.{
  type CrossBarError, KeyValue, bool, eq, float, int, max_length, max_value,
  min_length, min_value, not_eq, required, serializables_to_string, string,
  to_float, to_serializable, to_serializable_list, validate, validate_many,
  with_validator,
}

pub fn main() {
  gleeunit.main()
}

fn extract_failed_rule_name(errors: List(CrossBarError)) -> List(String) {
  list.map(errors, with: fn(error) { error.rule })
}

pub fn composite_test() {
  string("first_name", "John")
  |> required
  |> min_length(3)
  |> max_length(10)
  |> validate
  |> should.be_ok

  string("first_name", "John")
  |> required
  |> max_length(3)
  |> validate
  |> should.be_error

  string("first_name", "")
  |> required
  |> min_length(3)
  |> max_length(10)
  |> not_eq("empty string", "")
  |> validate
  |> should.be_error

  int("age", 18)
  |> to_float
  |> required
  |> min_value(18.0)
  |> max_value(21.0)
  |> validate
  |> should.be_ok

  int("age", 16)
  |> to_float
  |> required
  |> min_value(18.0)
  |> max_value(21.0)
  |> validate
  |> should.be_error

  float("age", 18.0)
  |> required
  |> min_value(18.0)
  |> max_value(21.0)
  |> validate
  |> should.be_ok

  float("age", 0.0)
  |> required
  |> min_value(18.0)
  |> max_value(21.0)
  |> validate
  |> should.be_error
}

pub fn validate_many_test() {
  let first_name =
    string("first_name", "John")
    |> required
    |> min_length(3)

  let last_name =
    string("last_name", "Doe")
    |> required
    |> min_length(3)

  // Make sure that keeping failed only works
  validate_many([first_name, last_name], keep_failed_only: True)
  |> should.equal([])

  validate_many([first_name, last_name], keep_failed_only: False)
  |> should.not_equal([])
}

pub fn to_serializable_test() {
  let expected =
    "{\"first_name\":{\"required\":\"is required\",\"min_length\":\"must be at least 3 characters\"},\"renamed_last_name\":{\"max_length\":\"must not be longer than 3 characters\"}}"

  let first_name =
    string("first_name", "")
    |> required
    |> min_length(3)
    |> validate
    |> to_serializable("", KeyValue)

  let last_name =
    string("last_name", "Smith")
    |> required
    |> min_length(1)
    |> max_length(3)
    |> validate
    |> to_serializable("renamed_last_name", KeyValue)

  [first_name, last_name]
  |> serializables_to_string
  |> should.equal(expected)
}

pub fn to_serializable_list_test() {
  let expected =
    "{\"first_name\":{\"required\":\"is required\",\"min_length\":\"must be at least 3 characters\"},\"last_name\":{\"max_length\":\"must not be longer than 3 characters\"}}"

  let first_name =
    string("first_name", "")
    |> required
    |> min_length(3)

  let last_name =
    string("last_name", "Smith")
    |> required
    |> min_length(1)
    |> max_length(3)

  [first_name, last_name]
  |> validate_many(False)
  |> to_serializable_list(KeyValue)
  |> serializables_to_string
  |> should.equal(expected)
}

pub fn has_errors_test() {
  let first_name =
    string("first_name", "")
    |> required
    |> min_length(3)

  let last_name =
    string("last_name", "Smith")
    |> required
    |> min_length(1)
    |> max_length(3)

  [first_name, last_name]
  |> validate_many(False)
  |> list.map(fn(f) { to_serializable(Error(f.1), "", KeyValue) })
  |> crossbar.has_errors
  |> should.equal(True)

  [first_name, last_name]
  |> validate_many(False)
  |> to_serializable_list(KeyValue)
  |> crossbar.has_errors
  |> should.equal(True)

  let fname =
    string("first_name", "John")
    |> required
    |> min_length(3)

  let lname =
    string("last_name", "Smith")
    |> required
    |> min_length(1)
    |> max_length(10)

  [fname, lname]
  |> validate_many(False)
  |> list.map(fn(f) { to_serializable(Error(f.1), "", KeyValue) })
  |> crossbar.has_errors
  |> should.equal(False)

  [fname, lname]
  |> validate_many(False)
  |> to_serializable_list(KeyValue)
  |> crossbar.has_errors
  |> should.equal(False)
}

pub fn required_test() {
  // any number other than 0 is considered not empty
  18
  |> int("18 is ok", _)
  |> required
  |> validate
  |> should.be_ok

  // 0 is considered empty
  0
  |> int("0 is empty", _)
  |> required
  |> validate
  |> should.be_error
  |> extract_failed_rule_name
  |> should.equal(["required"])

  // any float other than 0.0 is considered not empty
  0.1
  |> float("0.1 is ok", _)
  |> required
  |> validate
  |> should.be_ok

  // 0.0 is considered empty
  0.0
  |> float("0.0 is not ok", _)
  |> required
  |> validate
  |> should.be_error
  |> extract_failed_rule_name
  |> should.equal(["required"])

  // string with space only is empty
  " "
  |> string("string with space is empty", _)
  |> required
  |> validate
  |> should.be_error
  |> extract_failed_rule_name
  |> should.equal(["required"])

  // empty string
  ""
  |> string("empty string", _)
  |> required
  |> validate
  |> should.be_error
  |> extract_failed_rule_name
  |> should.equal(["required"])

  // Bools are not empty by default anyway
  True
  |> bool("True is ok", _)
  |> required
  |> validate
  |> should.be_ok

  False
  |> bool("False is ok", _)
  |> required
  |> validate
  |> should.be_ok
}

pub fn min_value_test() {
  5
  |> int("5 is greater than 2.0", _)
  |> to_float
  |> min_value(2.0)
  |> validate
  |> should.be_ok

  5
  |> int("5.1 is greater than 5", _)
  |> to_float
  |> min_value(5.1)
  |> validate
  |> should.be_error
  |> extract_failed_rule_name
  |> should.equal(["min_value"])

  5.1
  |> float("5.1 is greater than 5", _)
  |> min_value(5.0)
  |> validate
  |> should.be_ok

  5.1
  |> float("same values are okay", _)
  |> min_value(5.1)
  |> validate
  |> should.be_ok
}

pub fn max_value_test() {
  5
  |> int("5 is less than 6.0", _)
  |> to_float
  |> max_value(6.0)
  |> validate
  |> should.be_ok

  5
  |> int("5 is less than 5.1", _)
  |> to_float
  |> max_value(5.1)
  |> validate
  |> should.be_ok
}

// TODO: test more cases
pub fn min_length_test() {
  let should_fail = fn(v) {
    v
    |> should.be_error
    |> extract_failed_rule_name
    |> should.equal(["min_length"])
  }

  "hello"
  |> string("hello - min_length", _)
  |> min_length(5)
  |> validate
  |> should.be_ok

  "hello"
  |> string("hello - min_length - 6", _)
  |> min_length(6)
  |> validate
  |> should_fail

  "   "
  |> string("space is not a valid part of the string", _)
  |> min_length(1)
  |> validate
  |> should_fail

  "hell  "
  |> string("space is not a valid part of the string - hello", _)
  |> min_length(5)
  |> validate
  |> should_fail
}

// TODO: test more cases
pub fn max_length_test() {
  let should_fail = fn(v) {
    v
    |> should.be_error
    |> extract_failed_rule_name
    |> should.equal(["max_length"])
  }

  "hello"
  |> string("hello - max_length_pass", _)
  |> max_length(5)
  |> validate
  |> should.be_ok

  "hello"
  |> string("hello - max_length_fail", _)
  |> max_length(4)
  |> validate
  |> should_fail

  "   "
  |> string(
    "space is not a valid part of the string so should evaluate to nothing",
    _,
  )
  |> max_length(1)
  |> validate
  |> should.be_ok

  "hell  "
  |> string("space is not a valid part of the string - hell", _)
  |> max_length(5)
  |> validate
  |> should.be_ok
}

pub fn eq_test() {
  "hello"
  |> string("hello eq hello - ok", _)
  |> eq("other_hello", "hello")
  |> validate
  |> should.be_ok

  "hella"
  |> string("hella eq hello - error", _)
  |> eq("other_hello", "hello")
  |> validate
  |> should.be_error

  "hello "
  |> string("hello with space eq hello - error", _)
  |> eq("other_hello", "hello")
  |> validate
  |> should.be_error
}

pub fn not_eq_test() {
  "hello"
  |> string("hello not_eq hello - error", _)
  |> not_eq("other_hello", "hello")
  |> validate
  |> should.be_error

  "hella"
  |> string("hella not_eq hello - ok", _)
  |> not_eq("other_hello", "hello")
  |> validate
  |> should.be_ok

  "hello "
  |> string("hello with space not_eq hello - ok", _)
  |> not_eq("other_hello", "hello")
  |> validate
  |> should.be_ok
}

pub fn regex_test() {
  let assert Ok(hello123regex) = regex.from_string("^[a-p0-9]+$")

  "hello123"
  |> string("hello123 regex - a to p", _)
  |> crossbar.regex(
    "6 in total, alphanum",
    hello123regex,
    "expects to match pattern ^[a-p0-9]+$",
  )
  |> validate
  |> should.be_ok

  "zingo123"
  |> string("zingo123 regex - a to p", _)
  |> crossbar.regex(
    "6 in total, alphanum",
    hello123regex,
    "expects to match pattern ^[a-p0-9]+$",
  )
  |> validate
  |> should.be_error

  "hello1234"
  |> string("hello1234 regex - a to p", _)
  |> crossbar.regex(
    "6 in total, alphanum",
    hello123regex,
    "expects to match pattern ^[a-p0-9]+$",
  )
  |> validate
  |> should.be_ok

  "this is weird"
  |> string("this is weird regex - a to p", _)
  |> crossbar.regex(
    "6 in total, alphanum",
    hello123regex,
    "expects to match pattern ^[a-p0-9]+$",
  )
  |> validate
  |> should.be_error
}

pub fn validator_fn_test() {
  let is_even = fn(v) { v % 2 == 0 }
  let is_odd = fn(v) { v % 2 != 0 }
  let is_hello = fn(v) { v == "hello" }
  let starts_with_hello = fn(v) {
    let v = string.lowercase(v)
    case v {
      "hello" <> _ -> True
      _ -> False
    }
  }

  2
  |> int("2 is even", _)
  |> with_validator("is_even", is_even, "must be an even number")
  |> validate
  |> should.be_ok

  5
  |> int("5 is not even", _)
  |> with_validator("is_even", is_even, "must be an even number")
  |> validate
  |> should.be_error

  3
  |> int("3 is odd", _)
  |> with_validator("is_odd", is_odd, "must be an odd number")
  |> validate
  |> should.be_ok

  4
  |> int("4 is not odd", _)
  |> with_validator("is_odd", is_odd, "must be an odd number")
  |> validate
  |> should.be_error

  "hello"
  |> string("hello is equal to hello", _)
  |> with_validator("is_hello", is_hello, "must be hello")
  |> validate
  |> should.be_ok

  "hello "
  |> string("hello is not equal to hello", _)
  |> with_validator("is_hello", is_hello, "must be hello")
  |> validate
  |> should.be_error

  "hello"
  |> string("hello starts with hello", _)
  |> with_validator(
    "starts_with_hello",
    starts_with_hello,
    "must start with hello",
  )
  |> validate
  |> should.be_ok

  "Hello, world!"
  |> string("hello, world! starts with hello", _)
  |> with_validator(
    "starts_with_hello",
    starts_with_hello,
    "must start with hello",
  )
  |> validate
  |> should.be_ok

  "Hell yes!"
  |> string("hell yes! does not start with hello", _)
  |> with_validator(
    "starts_with_hello",
    starts_with_hello,
    "must start with hello",
  )
  |> validate
  |> should.be_error
}
