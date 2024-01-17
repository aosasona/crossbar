import gleam/dynamic.{type DecodeError, type Dynamic}
import gleam/float
import gleam/int
import gleam/result

fn cast(
  from: b,
  to: dynamic.Decoder(a),
) -> Result(a, List(dynamic.DecodeError)) {
  dynamic.from(from)
  |> to
  |> fn(x) {
    case x {
      Ok(v) -> Ok(v)
      Error(e) -> Error(e)
    }
  }
}

// These are potentially unsafe but I will try to restrict the data that will ever make it here anyway
pub fn int(from: b) -> Int {
  cast(from, dynamic.int)
  |> result.unwrap(0)
}

pub fn float(from: b) -> Float {
  cast(from, dynamic.float)
  |> result.unwrap(0.0)
}

pub fn string(from: b) -> String {
  cast(from, dynamic.string)
  |> result.unwrap("")
}

pub fn bool(from: b) -> Bool {
  cast(from, dynamic.bool)
  |> result.unwrap(False)
}

// Cast any value of the supported types to a string for printing
pub fn to_string(value: a) -> String {
  value
  |> dynamic.from
  |> dynamic.any([
    dynamic.string,
    bool_str_decoder,
    int_str_decoder,
    float_str_decoder,
  ])
  |> result.unwrap("")
}

fn bool_str_decoder(dyn: Dynamic) -> Result(String, List(DecodeError)) {
  result.map(dynamic.bool(dyn), fn(v) {
    case v {
      True -> "true"
      False -> "false"
    }
  })
}

fn int_str_decoder(dyn: Dynamic) -> Result(String, List(DecodeError)) {
  result.map(dynamic.int(dyn), fn(v) { int.to_string(v) })
}

fn float_str_decoder(dyn: Dynamic) -> Result(String, List(DecodeError)) {
  result.map(dynamic.float(dyn), fn(v) { float.to_string(v) })
}
