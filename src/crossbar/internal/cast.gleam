import gleam/dynamic
import gleam/result

fn cast(from: b, to: dynamic.Decoder(a)) -> Result(a, List(dynamic.DecodeError)) {
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
