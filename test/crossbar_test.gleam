import gleam/list
import gleeunit
import gleeunit/should
import crossbar.{
  type CrossBarError, bool, float, int, required, string, validate,
}

pub fn main() {
  gleeunit.main()
}

// gleeunit test functions end in `_test`
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

fn extract_failed_rule_name(errors: List(CrossBarError)) -> List(String) {
  list.map(errors, with: fn(error) { error.rule })
}
