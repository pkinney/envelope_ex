# Envelope

[![Build Status](https://travis-ci.org/pkinney/envelope.svg?branch=master)](https://travis-ci.org/pkinney/envelope)
[![Hex.pm](https://img.shields.io/hexpm/v/envelope.svg)](https://hex.pm/packages/envelope)

A library for calculating envelopes of geometries and tools to compare them.
This is most useful as an approximation of spacial relationships between more
complicated geometries.

## Installation

```elixir
defp deps do
  [{:envelope, "~> 0.1.0"}]
end
```

## Usage

**[Full Documentation](https://hexdocs.pm/envelope/Envelope.html)**

The `Envelope` module provides a method `from_geo` that accepts a struct
generated via the Geo library (https://github.com/bryanjos/geo) and returns an
`Envelope` struct containing the maximum extent in the `x` and `y` direction.

```elixir
Envelope.from_geo( %Geo.Polygon{coordinates: [[{2, -2}, {20, -2}, {11, 11}, {2, -2}]]} )
# => %Envelope{ min_x: 2, min_y: -2, max_x: 20, max_y: 11 }

env = %Envelope{min_x: -1, min_y: 2, max_x: 1, max_y: 5}
Envelope.expand(env, %Geo.Polygon{coordinates: [[{2, -2}, {20, -2}, {11, 11}, {2, -2}]]})
# => %Envelope{ min_x: -1, min_y: -2, max_x: 20, max_y: 11 }
```
