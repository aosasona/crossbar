# crossbar

[![Package Version](https://img.shields.io/hexpm/v/crossbar)](https://hex.pm/packages/crossbar)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/crossbar/)

## Usage

```gleam
import gleam/io
import crossbar.{int, max_size, min_size, required, validate}

pub fn main() {
  int("age", 16)
  |> required
  |> min_size(18.0)
  |> max_size(21.0)
  |> validate
  |> io.debug
}
```

The snippet above will return the following error:

> Error([FailedRule("age", "min_size", "must be at least 18.0")])

## Installation

```sh
gleam add crossbar
```

Documentation can be found at <https://hexdocs.pm/crossbar>.
