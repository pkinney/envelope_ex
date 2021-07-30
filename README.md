# Envelope

[![Build Status](https://travis-ci.org/pkinney/envelope_ex.svg?branch=master)](https://travis-ci.org/pkinney/envelope_ex)
[![Hex.pm](https://img.shields.io/hexpm/v/envelope.svg)](https://hex.pm/packages/envelope)

A library for calculating envelopes (axis-aligned bounding boxes) of geometries and tools to compare them.
This is most useful as an approximation of spacial relationships between more
complicated geometries.

## Installation

```elixir
defp deps do
  [{:envelope, "~> 1.2"}]
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

Envelope.empty
|> Envelope.expand(%Envelope{ min_x: 0, min_y: -2, max_x: 12, max_y: 11 })
|> Envelope.expand(%Geo.Polygon{coordinates: [[{2, -2}, {20, -2}, {11, 11}, {2, -2}]]})
|> Envelope.expand(%{type: "Point", coordinates: {-1, 3}})
# => %Envelope{ min_x: -1, min_y: -2, max_x: 20, max_y: 11 }
```

Envelopes can then be used to estimate spatial relationships between more complex shapes.

```elixir
Envelope.intersects?(
  %Envelope{ min_x: -1, min_y: -5, max_x: 23, max_y: 14 },
  %Envelope{ min_x: 0, min_y: 3, max_x: 7, max_y: 4 })
# => true

Envelope.contains?(
  %Envelope{ min_x: -1, min_y: 5, max_x: 23, max_y: 14 },
  %{type: "Point", coordinates: {0, 4}})
# => false
```

## Applicaiton

In the context of a larger Geometry/GIS application, Envelopes can be used to
drastically decrease processing overhead for comparing two geometries that are
likely to be disjoint.  For example, determining whether a point enters a
complex geofence or finding shape collisions among a large number of spread
out polygons.

This is based on the fact that Geometries (Polygon, LineString, MultiPolgyon,
etc.) with disjoint Envelopes will be disjoint.  Said another way, Geometries
will intersect if and only if their Envelopes intersect.

Depending on the unique environment and use case, it will be more efficient to
calculate Envelopes on the fly or calculate the Envelope and cache it.  Many
databases will do an bounding-box check internally, but for those that don't, storing
the extents along each axis and preforming a range change before pulling
a large geometry from the database will greatly improve performance.

For example, using [Topo](https://github.com/pkinney/topo) as and underlying
geometry library:

```elixir
def intersect?(poly1, poly2) do
  # calculate the envelope or (better yet) pull it from cache
  poly1_env = Envelope.from_geo(poly1)
  poly2_env = Envelope.from_geo(poly2)

  case Envelope.intersects?(poly1_env, poly2_env) do
    true -> # envelopes intersect, so let's check the polygons directly
      Topo.intersects?(poly1, poly2)
    false -> # envelopes don't intersect, so no reason to check the polygon intersection
      false
  end
end
```

or more concisely

```elixir
Envelope.intersects?(Envelope.from_geo(poly1), Envelope.from_geo(poly2)) && Topo.intersects?(poly1, poly2)
```
