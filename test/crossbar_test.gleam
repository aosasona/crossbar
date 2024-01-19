import gleam/list
import gleam/option.{None, Some}
import gleeunit
import gleeunit/should
import crossbar.{
  type CrossBarError, bool, float, int, max_length, max_value, min_length,
  min_value, optional_float, optional_int, optional_string, required, string,
  validate,
}

pub fn main() {
  gleeunit.main()
}

fn extract_failed_rule_name(errors: List(CrossBarError)) -> List(String) {
  list.map(errors, with: fn(error) { error.rule })
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

  // Some is not empty if the content is not empty
  Some("hello")
  |> optional_string("Some is ok if content is not empty", _)
  |> required
  |> validate
  |> should.be_ok

  // Some is empty if the content is empty
  Some("")
  |> optional_string("Some is not ok if content is empty", _)
  |> required
  |> validate
  |> should.be_error
  |> extract_failed_rule_name
  |> should.equal(["required"])

  // None is empty
  None
  |> optional_string("None is not ok", _)
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
  |> min_value(2.0)
  |> validate
  |> should.be_ok

  5
  |> int("5.1 is greater than 5", _)
  |> min_value(5.1)
  |> validate
  |> should.be_error
  |> extract_failed_rule_name
  |> should.equal(["min_value"])

  Some(5)
  |> optional_int("Some(5) is greater than 2.0", _)
  |> min_value(2.0)
  |> validate
  |> should.be_ok

  None
  |> optional_int("None is not greater than 2.0", _)
  |> min_value(2.0)
  |> validate
  |> should.be_error
  |> extract_failed_rule_name
  |> should.equal(["min_value"])

  Some(5.5)
  |> optional_float("Some(5.5) is greater than 2.0", _)
  |> min_value(2.0)
  |> validate
  |> should.be_ok

  Some(5.5)
  |> optional_float("Some(5.5) is NOT greater than 5.6", _)
  |> min_value(5.6)
  |> validate
  |> should.be_error
  |> extract_failed_rule_name
  |> should.equal(["min_value"])

  None
  |> optional_float("None is not greater than 2.0", _)
  |> min_value(2.0)
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

  "hello"
  |> string("hello is 5 bytes", _)
  |> min_value(5.0)
  |> validate
  |> should.be_ok

  "hello   "
  |> string("hello with space is still not less than 5 bytes", _)
  |> min_value(5.0)
  |> validate
  |> should.be_ok

  "hello"
  |> string("hello is not 5.1 bytes", _)
  |> min_value(5.1)
  |> validate
  |> should.be_error
  |> extract_failed_rule_name
  |> should.equal(["min_value"])

  True
  |> bool("Bools are just 1 or 0", _)
  |> min_value(5.0)
  |> validate
  |> should.be_error
  |> extract_failed_rule_name
  |> should.equal(["min_value"])

  False
  |> bool("Bools are just 1 or 0", _)
  |> min_value(5.0)
  |> validate
  |> should.be_error
  |> extract_failed_rule_name
  |> should.equal(["min_value"])
}

pub fn max_value_test() {
  5
  |> int("5 is less than 6.0", _)
  |> max_value(6.0)
  |> validate
  |> should.be_ok

  5
  |> int("5 is less than 5.1", _)
  |> max_value(5.1)
  |> validate
  |> should.be_ok

  Some(5)
  |> optional_int("Some(5) is less than 6.0", _)
  |> max_value(6.0)
  |> validate
  |> should.be_ok

  None
  |> optional_int("None is less than 6.0", _)
  |> max_value(6.0)
  |> validate
  |> should.be_ok

  Some(5.5)
  |> optional_float("Some(5.5) is less than 6.0", _)
  |> max_value(6.0)
  |> validate
  |> should.be_ok

  Some(5.5)
  |> optional_float("Some(5.5) is less than 5.6", _)
  |> max_value(5.6)
  |> validate
  |> should.be_ok

  Some(5.6)
  |> optional_float("Some(5.6) is equal to 5.6", _)
  |> max_value(5.6)
  |> validate
  |> should.be_ok

  Some(5.7)
  |> optional_float("Some(5.7) is NOT less than 5.6", _)
  |> max_value(5.6)
  |> validate
  |> should.be_error
  |> extract_failed_rule_name
  |> should.equal(["max_value"])

  "hello"
  |> string("hello is 5 bytes", _)
  |> max_value(5.0)
  |> validate
  |> should.be_ok

  "hello   "
  |> string("hello with space is greater than 5 bytes", _)
  |> max_value(5.0)
  |> validate
  |> should.be_error
  |> extract_failed_rule_name
  |> should.equal(["max_value"])

  "hello"
  |> string("hello is greater than 4 bytes", _)
  |> max_value(4.0)
  |> validate
  |> should.be_error
  |> extract_failed_rule_name
  |> should.equal(["max_value"])
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

  245
  |> int("245 - min_length", _)
  |> min_length(3)
  |> validate
  |> should.be_ok

  245
  |> int("245 - min_length (4)", _)
  |> min_length(4)
  |> validate
  |> should.be_error
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
