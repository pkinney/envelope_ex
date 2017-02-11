defmodule PointPolygonBench do
  use Benchfella

  @states Path.join([ "bench", "shapes", "states.json" ])
    |> File.read!
    |> Poison.decode!
    |> Map.fetch!("features")
    |> Enum.map(&(&1["geometry"]))
    |> Enum.map(&Geo.JSON.decode/1)

  @counties Path.join([ "bench", "shapes", "counties.json" ])
    |> File.read!
    |> Poison.decode!
    |> Map.fetch!("features")
    |> Enum.map(&(&1["geometry"]))
    |> Enum.map(&Geo.JSON.decode/1)

  @cities Path.join([ "bench", "shapes", "cities.json" ])
    |> File.read!
    |> Poison.decode!
    |> Map.fetch!("features")
    |> Enum.map(&(&1["geometry"]))
    |> Enum.map(&Geo.JSON.decode/1)

  bench "Point in Polygon Envelope contains check" do
    [polygon] = Enum.take_random(@states, 1)
    [point] = Enum.take_random(@cities, 1)

    Envelope.contains?(polygon, point)
    :ok
  end

  # bench "Point in Polygon Envelope contains check with extracted point" do
  #   [polygon] = Enum.take_random(@states, 1)
  #   [%{coordinates: {x, y}}] = Enum.take_random(@cities, 1)

  #   Envelope.contains?(polygon, {x, y})
  #   :ok
  # end

  # bench "Point in Polygon Envelope intersects check" do
  #   [polygon] = Enum.take_random(@states, 1)
  #   [point] = Enum.take_random(@cities, 1)

  #   Envelope.intersects?(polygon, point)
  #   :ok
  # end
end