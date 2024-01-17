import gleam/list
import gleam/option.{None, Some}
import gleeunit
import gleeunit/should
import crossbar.{
  type CrossBarError, bool, float, int, max_size, min_size, optional_float,
  optional_int, optional_string, required, string, validate,
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

pub fn min_size_test() {
  5
  |> int("5 is greater than 2.0", _)
  |> min_size(2.0)
  |> validate
  |> should.be_ok

  5
  |> int("5.1 is greater than 5", _)
  |> min_size(5.1)
  |> validate
  |> should.be_error
  |> extract_failed_rule_name
  |> should.equal(["min_size"])

  Some(5)
  |> optional_int("Some(5) is greater than 2.0", _)
  |> min_size(2.0)
  |> validate
  |> should.be_ok

  None
  |> optional_int("None is not greater than 2.0", _)
  |> min_size(2.0)
  |> validate
  |> should.be_error
  |> extract_failed_rule_name
  |> should.equal(["min_size"])

  Some(5.5)
  |> optional_float("Some(5.5) is greater than 2.0", _)
  |> min_size(2.0)
  |> validate
  |> should.be_ok

  Some(5.5)
  |> optional_float("Some(5.5) is NOT greater than 5.6", _)
  |> min_size(5.6)
  |> validate
  |> should.be_error
  |> extract_failed_rule_name
  |> should.equal(["min_size"])

  None
  |> optional_float("None is not greater than 2.0", _)
  |> min_size(2.0)
  |> validate
  |> should.be_error
  |> extract_failed_rule_name
  |> should.equal(["min_size"])

  5.1
  |> float("5.1 is greater than 5", _)
  |> min_size(5.0)
  |> validate
  |> should.be_ok

  5.1
  |> float("same values are okay", _)
  |> min_size(5.1)
  |> validate
  |> should.be_ok

  "hello"
  |> string("hello is 5 bytes", _)
  |> min_size(5.0)
  |> validate
  |> should.be_ok

  "hello   "
  |> string("hello with space is still not less than 5 bytes", _)
  |> min_size(5.0)
  |> validate
  |> should.be_ok

  "hello"
  |> string("hello is not 5.1 bytes", _)
  |> min_size(5.1)
  |> validate
  |> should.be_error
  |> extract_failed_rule_name
  |> should.equal(["min_size"])

  True
  |> bool("Bools are just 1 or 0", _)
  |> min_size(5.0)
  |> validate
  |> should.be_error
  |> extract_failed_rule_name
  |> should.equal(["min_size"])

  False
  |> bool("Bools are just 1 or 0", _)
  |> min_size(5.0)
  |> validate
  |> should.be_error
  |> extract_failed_rule_name
  |> should.equal(["min_size"])
}

pub fn max_size_test() {
  5
  |> int("5 is less than 6.0", _)
  |> max_size(6.0)
  |> validate
  |> should.be_ok

  5
  |> int("5 is less than 5.1", _)
  |> max_size(5.1)
  |> validate
  |> should.be_ok

  Some(5)
  |> optional_int("Some(5) is less than 6.0", _)
  |> max_size(6.0)
  |> validate
  |> should.be_ok

  None
  |> optional_int("None is less than 6.0", _)
  |> max_size(6.0)
  |> validate
  |> should.be_ok

  Some(5.5)
  |> optional_float("Some(5.5) is less than 6.0", _)
  |> max_size(6.0)
  |> validate
  |> should.be_ok

  Some(5.5)
  |> optional_float("Some(5.5) is less than 5.6", _)
  |> max_size(5.6)
  |> validate
  |> should.be_ok

  Some(5.6)
  |> optional_float("Some(5.6) is equal to 5.6", _)
  |> max_size(5.6)
  |> validate
  |> should.be_ok

  Some(5.7)
  |> optional_float("Some(5.7) is NOT less than 5.6", _)
  |> max_size(5.6)
  |> validate
  |> should.be_error
  |> extract_failed_rule_name
  |> should.equal(["max_size"])

  "hello"
  |> string("hello is 5 bytes", _)
  |> max_size(5.0)
  |> validate
  |> should.be_ok

  "hello   "
  |> string("hello with space is greater than 5 bytes", _)
  |> max_size(5.0)
  |> validate
  |> should.be_error
  |> extract_failed_rule_name
  |> should.equal(["max_size"])

  "hello"
  |> string("hello is greater than 4 bytes", _)
  |> max_size(4.0)
  |> validate
  |> should.be_error
  |> extract_failed_rule_name
  |> should.equal(["max_size"])
}
