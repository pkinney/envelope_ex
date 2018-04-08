defmodule EnvelopeBench do
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

  def take_from(list) do
    list |> Enum.take_random(1) |> hd
  end

  bench "Envelope of a Polygon" ,
    polygon: take_from(@states ++ @counties)
  do
    Envelope.from_geo(polygon)
    :ok
  end

  bench "Envelope of a Point" ,
    point: take_from(@cities)
  do
    Envelope.from_geo(point)
    :ok
  end
end