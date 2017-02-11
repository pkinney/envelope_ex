defmodule PointPolygonBench do
  use Benchfella

  @states Path.join([ "bench", "shapes", "states.json" ])
    |> File.read!
    |> Poison.decode!
    |> Map.fetch!("features")
    |> Enum.map(&(&1["geometry"]))
    |> Enum.map(&Geo.JSON.decode/1)
    |> Enum.shuffle
    |> Enum.take(10)

  @counties Path.join([ "bench", "shapes", "counties.json" ])
    |> File.read!
    |> Poison.decode!
    |> Map.fetch!("features")
    |> Enum.map(&(&1["geometry"]))
    |> Enum.map(&Geo.JSON.decode/1)
    |> Enum.shuffle
    |> Enum.take(10)

  @cities Path.join([ "bench", "shapes", "cities.json" ])
    |> File.read!
    |> Poison.decode!
    |> Map.fetch!("features")
    |> Enum.map(&(&1["geometry"]))
    |> Enum.map(&Geo.JSON.decode/1)


  def take_from(list) do
    list |> Enum.take_random(1) |> hd
  end

  # bench "Point in Polygon Envelope contains check",
  #   polygon: take_from(@states),
  #   point: take_from(@cities)
  # do
  #   Envelope.contains?(polygon, point)
  #   :ok
  # end

  # bench "Point in Polygon Envelope contains check with extracted point",
  #   polygon: take_from(@states),
  #   point: take_from(@cities)
  # do
  #   Envelope.contains?(polygon, point.coordinates)
  #   :ok
  # end

  bench "Polygon in Polygon Envelope contains check",
    poly1: take_from(@states),
    poly2: take_from(@counties)
  do
    Envelope.contains?(poly1, poly2)
    :ok
  end

  bench "Polygon in Polygon Envelope intersects check",
    poly1: take_from(@states),
    poly2: take_from(@counties)
  do
    Envelope.intersects?(poly1, poly2)
    :ok
  end
end