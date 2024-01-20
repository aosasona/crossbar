import gleam/list
import gleeunit
import gleeunit/should
import crossbar.{
  type CrossBarError, bool, float, int, max_length, max_value, min_length,
  min_value, required, string, to_float, validate,
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
