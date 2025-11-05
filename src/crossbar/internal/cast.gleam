import gleam/dynamic.{type Dynamic}
import gleam/dynamic/decode.{type Decoder}
import gleam/float
import gleam/int
import gleam/result

// Cast any value to the Dynamic type
@external(erlang, "crossbar_ffi", "identity")
@external(javascript, "../crossbar_ffi.mjs", "identity")
pub fn to_dynamic(value: a) -> Dynamic

// Cast a Dynamic value to any type
@external(erlang, "crossbar_ffi", "identity")
@external(javascript, "../crossbar_ffi.mjs", "identity")
pub fn to_generic(value: Dynamic) -> a

fn cast(from: b, decoder: Decoder(a)) -> Result(a, List(decode.DecodeError)) {
  from |> to_dynamic |> decode.run(decoder)
}

// These are unsafe as they create defaults on error instead of bubbling up the errors but we will try to restrict the data that will ever make it here with the type system anyway
pub fn int(from: b) -> Int {
  cast(from, decode.int)
  |> result.unwrap(0)
}

pub fn float(from: b) -> Float {
  cast(from, decode.float)
  |> result.unwrap(0.0)
}

pub fn string(from: b) -> String {
  cast(from, decode.string)
  |> result.unwrap("")
}

pub fn bool(from: b) -> Bool {
  cast(from, decode.bool)
  |> result.unwrap(False)
}

// Cast any value of the supported types to a string for printing
pub fn to_string(value: a) -> String {
  let bool_to_string = fn(value: Bool) -> String {
    case value {
      True -> "true"
      False -> "false"
    }
  }

  let combined_decoder: Decoder(String) =
    decode.one_of(decode.string, or: [
      decode.bool |> decode.map(bool_to_string),
      decode.int |> decode.map(int.to_string),
      decode.float |> decode.map(float.to_string),
    ])

  value
  |> to_dynamic
  |> decode.run(combined_decoder)
  |> result.unwrap("<unrepresentable>")
}
