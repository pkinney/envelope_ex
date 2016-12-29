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

  @type points :: {number, number}
                  | list
                  | %{coordinates: list}
                  | %Geo.Point{}
                  | %Geo.MultiPoint{}
                  | %Geo.LineString{}
                  | %Geo.MultiLineString{}
                  | %Geo.Polygon{}
                  | %Geo.MultiPolygon{}

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

      iex> Envelope.expand(Envelope.empty, %Envelope{ min_x: 0, min_y: -2, max_x: 20, max_y: 11 })
      %Envelope{ min_x: 0, min_y: -2, max_x: 20, max_y: 11 }

      iex> Envelope.expand(Envelope.empty, Envelope.empty) |> Envelope.empty?
      true
  """
  @spec expand(%Envelope{}, {number, number} | %Envelope{} | points) :: %Envelope{}
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
  Returns whether two envelopes touch or intersect.

  ## Examples
      iex> Envelope.intersect?(
      ...> %Envelope{ min_x: -1, min_y: -5, max_x: 23, max_y: 14 },
      ...> %Envelope{ min_x: 0, min_y: 3, max_x: 7, max_y: 4 })
      true

      iex> Envelope.intersect?(
      ...> %Envelope{ min_x: -1, min_y: 5, max_x: 23, max_y: 14 },
      ...> %Envelope{ min_x: 0, min_y: -3, max_x: 7, max_y: 4 })
      false
  """
  @spec intersect?(%Envelope{}, %Envelope{}) :: boolean
  def intersect?(%Envelope{} = env1, %Envelope{} = env2) do
    cond do
      env1.min_x > env2.max_x -> false
      env1.max_x < env2.min_x -> false
      env1.min_y > env2.max_y -> false
      env1.max_y < env2.min_y -> false
      true -> true
    end
  end
end
