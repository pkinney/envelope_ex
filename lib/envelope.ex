defmodule Envelope do
  @moduledoc ~S"""
  A library for calculating envelopes of geometries and tools to compare them.
  This is most useful as an approximation of spacial relationships between more
  complicated geometries.

      iex> Envelope.from_geo( %Geo.Polygon{coordinates: [[{2, -2}, {20, -2}, {11, 11}, {2, -2}]]} )
      %Envelope{ min_x: 2, min_y: -2, max_x: 20, max_y: 11 }

      iex> Envelope.from_geo( %Geo.LineString{coordinates: [{1, 3}, {2, -1}, {0, -1}, {1, 3}]} )
      %Envelope{ min_x: 0, min_y: -1, max_x: 2, max_y: 3 }

  You can also expand an existing Envelope with a geometry or another Envelope

      iex> a = Envelope.from_geo( %Geo.Polygon{coordinates: [[{2, -2}, {20, -2}, {11, 11}, {2, -2}]]} )
      ...> b = %Geo.LineString{coordinates: [{1, 3}, {2, -1}, {0, -1}, {1, 3}]}
      ...> Envelope.expand(a, b)
      %Envelope{ min_x: 0, min_y: -2, max_x: 20, max_y: 11 }
  """

  defstruct min_x: 0, min_y: 0, max_x: 0, max_y: 0

  @type point :: {number, number}
  @type points :: point
                  | list
                  | %{coordinates: list}
                  | %Geo.Point{}
                  | %Geo.MultiPoint{}
                  | %Geo.LineString{}
                  | %Geo.MultiLineString{}
                  | %Geo.Polygon{}
                  | %Geo.MultiPolygon{}

  alias Distance.GreatCircle

  @doc ~S"""
  Returns an `Envelope` that represents the extent of the geometry or
  coordinates.

  ## Examples
      iex> Envelope.from_geo %{coordinates: [{11, 10}, {4, 2.5}, {16, 2.5}, {11, 10}]}
      %Envelope{ max_x: 16, max_y: 10, min_x: 4, min_y: 2.5 }

      iex> Envelope.from_geo [{11, 10}, {4, 2.5}, {16, 2.5}, {11, 10}]
      %Envelope{ max_x: 16, max_y: 10, min_x: 4, min_y: 2.5 }

      iex> Envelope.from_geo %Geo.Polygon{coordinates: [[{1, 3}, {2, -1}, {0, -1}, {1, 3}]]}
      %Envelope{ min_x: 0, min_y: -1, max_x: 2, max_y: 3 }

      iex> Envelope.from_geo {1, 3}
      %Envelope{ min_x: 1, min_y: 3, max_x: 1, max_y: 3 }
  """
  @spec from_geo(points) :: %Envelope{}
  def from_geo({x, y}), do: %Envelope{min_x: x, min_y: y, max_x: x, max_y: y}
  def from_geo(%Geo.Point{coordinates: {x, y}}), do: %Envelope{min_x: x, min_y: y, max_x: x, max_y: y}
  def from_geo(%{coordinates: coordinates}), do: from_geo(coordinates)
  def from_geo(coordinates) when is_list(coordinates) do
    coordinates
    |> List.flatten
    |> Enum.reduce(Envelope.empty, &(expand(&2, &1)))
  end

  @doc ~S"""
  Returns an `Envelope` that represents no extent at all.  This is primarily
  a convenience function for starting an expanding Envelope. Internally,
  "empty" Envelopes are represented with `nil` values for all extents.

  Note that there is a important distinction between an empty Envelope and
  an Envelope around a single Point (where the min and max for each axis are
  real numbers but may represent zero area).

  ## Examples
      iex> Envelope.empty
      %Envelope{max_x: nil, max_y: nil, min_x: nil, min_y: nil}

      iex> Envelope.empty |> Envelope.empty?
      true
  """
  @spec empty() :: %Envelope{}
  def empty, do: %Envelope{min_x: nil, min_y: nil, max_x: nil, max_y: nil}

  @doc ~S"""
  Returns `true` if the given envelope is empty (has non-existent extent),
  otherwise `false`

  ## Examples
      iex> Envelope.empty |> Envelope.empty?
      true

      iex> %Envelope{ min_x: 0, min_y: -1, max_x: 2, max_y: 3 } |> Envelope.empty?
      false
  """
  @spec empty?(%Envelope{}) :: boolean
  def empty?(%Envelope{min_x: nil, min_y: nil, max_x: nil, max_y: nil}), do: true
  def empty?(%Envelope{}), do: false

  @doc ~S"""
  Returns a new Envelope that is expanded to include an additional geometry.

  ## Examples
      iex> a = Envelope.from_geo(%Geo.Polygon{coordinates: [[{2, -2}, {20, -2}, {11, 11}, {2, -2}]]})
      ...> b = %Geo.LineString{coordinates: [{1, 3}, {2, -1}, {0, -1}, {1, 3}]}
      ...> Envelope.expand(a, b)
      %Envelope{ min_x: 0, min_y: -2, max_x: 20, max_y: 11 }

      iex> a = %Envelope{ min_x: 0, min_y: -2, max_x: 20, max_y: 11 }
      ...> b = %Envelope{ min_x: 2, min_y: -3, max_x: 12, max_y: -2 }
      ...> Envelope.expand(a, b)
      %Envelope{ min_x: 0, min_y: -3, max_x: 20, max_y: 11 }

      iex> Envelope.empty
      ...> |> Envelope.expand(%Envelope{ min_x: 0, min_y: -2, max_x: 12, max_y: 11 })
      ...> |> Envelope.expand(%Geo.Polygon{coordinates: [[{2, -2}, {20, -2}, {11, 11}, {2, -2}]]})
      ...> |> Envelope.expand(%{type: "Point", coordinates: {-1, 3}})
      %Envelope{ min_x: -1, min_y: -2, max_x: 20, max_y: 11 }

      iex> Envelope.expand(Envelope.empty, Envelope.empty) |> Envelope.empty?
      true
  """
  @spec expand(%Envelope{}, point | %Envelope{} | points) :: %Envelope{}
  def expand(%Envelope{} = env1, %Envelope{} = env2) do
    cond do
      Envelope.empty?(env1) -> env2
      Envelope.empty?(env2) -> env1
      true                  -> %Envelope{
                                min_x: min(env1.min_x, env2.min_x),
                                min_y: min(env1.min_y, env2.min_y),
                                max_x: max(env1.max_x, env2.max_x),
                                max_y: max(env1.max_y, env2.max_y)
                              }
    end
  end
  def expand(%Envelope{} = env, other), do: expand(env, from_geo(other))

  @doc ~S"""
  Returns a new Envelope that is expanded in positive and negative directions
  in each axis by `radius`.

  ## Examples
      iex> Envelope.expand_by(Envelope.from_geo(%Geo.Polygon{coordinates: [[{2, -2}, {20, -2}, {11, 11}, {2, -2}]]}), 3)
      %Envelope{ min_x: -1, min_y: -5, max_x: 23, max_y: 14 }

      iex> Envelope.expand_by(Envelope.empty, 4) |> Envelope.empty?
      true
  """
  @spec expand_by(%Envelope{}, number) :: %Envelope{}
  def expand_by(%Envelope{} = env, radius) when is_number(radius) and radius >= 0 do
    case Envelope.empty? env do
      true  -> env
      false -> %Envelope{
                  min_x: env.min_x - radius,
                  min_y: env.min_y - radius,
                  max_x: env.max_x + radius,
                  max_y: env.max_y + radius
                }
    end
  end

  @doc ~S"""
  Simple distance from the left bounadary to the right boundary of the Envelope.

  ## Examples
      iex> Envelope.width(Envelope.from_geo(%Geo.Polygon{coordinates: [[{2, -2}, {20, -2}, {11, 11}, {2, -2}]]}))
      18
  """
  @spec width(%Envelope{}) :: number
  def width(%Envelope{} = env) do
    env.max_x - env.min_x
  end

  @doc ~S"""
  When an Envelope's coordinates are in degress of longitude and latitude, calculates the
  great circle distance between the center of the east and west extent in meters.

  ## Examples
      iex> Envelope.width_gc(Envelope.from_geo(%Geo.Polygon{coordinates: [[{2, -2}, {20, -2}, {11, 11}, {2, -2}]]})) |> round
      1982362
  """
  @spec width_gc(%Envelope{}) :: number
  def width_gc(%Envelope{} = env) do
    bottom = GreatCircle.distance(
      {env.min_x, env.min_y},
      {env.max_x, env.min_y})
    top = GreatCircle.distance(
      {env.min_x, env.max_y},
      {env.max_x, env.max_y})

    (bottom + top) / 2.0
  end

  @doc ~S"""
  Simple distance from the bottom bounadary to the top boundary of the Envelope.

  ## Examples
      iex> Envelope.height(Envelope.from_geo(%Geo.Polygon{coordinates: [[{2, -2}, {20, -2}, {11, 11}, {2, -2}]]}))
      13
  """
  @spec height(%Envelope{}) :: number
  def height(%Envelope{} = env) do
    env.max_y - env.min_y
  end

  @doc ~S"""
  When an Envelope's coordinates are in degress of longitude and latitude, calculates the
  great circle distance between the center of the north and south extent in meters.

  ## Examples
      iex> Envelope.height_gc(Envelope.from_geo(%Geo.Polygon{coordinates: [[{2, -2}, {20, -2}, {11, 11}, {2, -2}]]})) |> round
      1445536
  """
  @spec height_gc(%Envelope{}) :: number
  def  height_gc(%Envelope{} = env) do
    GreatCircle.distance({env.min_x, env.min_y}, {env.min_x, env.max_y})
  end

  @doc ~S"""
  Calculates the simple area of an Envelope.

  ## Examples
      iex> Envelope.area(Envelope.from_geo(%Geo.Polygon{coordinates: [[{2, -2}, {20, -2}, {11, 11}, {2, -2}]]}))
      234
  """
  @spec area(%Envelope{}) :: number
  def area(%Envelope{} = env) do
    width(env) * height(env)
  end

  @doc ~S"""
  Estimates the area of an Envelope in square meters when the Envelope's coordinates are in degress of longitude and latitude.

  ## Examples
      iex> Envelope.area_gc(Envelope.from_geo(%Geo.Polygon{coordinates: [[{2, -2}, {20, -2}, {11, 11}, {2, -2}]]})) |> round
      2865575088701
  """
  @spec area_gc(%Envelope{}) :: number
  def area_gc(%Envelope{} = env) do
    width_gc(env) * height_gc(env)
  end

  @doc ~S"""
  Returns whether one envelope fully contains another envelope or point.

  ## Examples
      iex> Envelope.contains?(
      ...> %Envelope{ min_x: -1, min_y: -5, max_x: 23, max_y: 14 },
      ...> %Envelope{ min_x: 0, min_y: 3, max_x: 7, max_y: 4 })
      true

      iex> Envelope.contains?(
      ...> %Envelope{ min_x: -1, min_y: 5, max_x: 23, max_y: 14 },
      ...> %Envelope{ min_x: -2, min_y: 5, max_x: 7, max_y: 4 })
      false

      iex> Envelope.contains?(
      ...> %Geo.Polygon{ coordinates: [{-1, 3}, {-3, -1}, { 5, -3}, {4, 12}, {-2, 11}, {-1, 3}] },
      ...> {0, 11})
      true
  """
  @spec contains?(%Envelope{} | points, %Envelope{} | points) :: boolean
  def contains?(%Envelope{} = env, {x, y}) do
    env.min_x <= x
    && env.min_y <= y
    && env.max_x >= x
    && env.max_y >= y
  end
  def contains?(%Envelope{} = env, %{coordinates: {x, y}}), do: contains?(env, {x, y})
  def contains?(%Envelope{} = env1, %Envelope{} = env2) do
    env1.min_x <= env2.min_x
    && env1.min_y <= env2.min_y
    && env1.max_x >= env2.max_x
    && env1.max_y >= env2.max_y
  end
  def contains?(%Envelope{} = env1, other), do: contains?(env1, from_geo(other))
  def contains?(a, b), do: contains?(from_geo(a), b)

  @doc ~S"""
  The inverse of the relationship tested by Envelope#contains?

  ## Examples
      iex> Envelope.within?(
      ...> %Envelope{ min_x: 0, min_y: 3, max_x: 7, max_y: 4 },
      ...> %Envelope{ min_x: -1, min_y: -5, max_x: 23, max_y: 14 })
      true

      iex> Envelope.within?(
      ...> %Geo.Polygon{ coordinates: [{-1, 3}, {-3, -1}, { 5, -3}, {4, 12}, {-2, 11}, {-1, 3}] },
      ...> {0, 11})
      false
  """
  @spec within?(%Envelope{} | points, %Envelope{} | points) :: boolean
  def within?(a, b), do: contains?(b, a)

  @doc ~S"""
  Returns whether two envelopes touch or intersect.

  ## Examples
      iex> Envelope.intersects?(
      ...> %Envelope{ min_x: -1, min_y: -5, max_x: 23, max_y: 14 },
      ...> %Envelope{ min_x: 0, min_y: 3, max_x: 7, max_y: 4 })
      true

      iex> Envelope.intersects?(
      ...> %Envelope{ min_x: -1, min_y: 5, max_x: 23, max_y: 14 },
      ...> %Envelope{ min_x: 0, min_y: -3, max_x: 7, max_y: 4 })
      false
  """
  @spec intersects?(%Envelope{} | points, %Envelope{} | points) :: boolean
  def intersects?(%Envelope{} = env1, %Envelope{} = env2) do
    cond do
      env1.min_x > env2.max_x -> false
      env1.max_x < env2.min_x -> false
      env1.min_y > env2.max_y -> false
      env1.max_y < env2.min_y -> false
      true -> true
    end
  end
  def intersects?(a, b), do: intersects?(from_geo(a), from_geo(b))
end
