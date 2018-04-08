defmodule EnvelopeTest do
  use ExUnit.Case
  doctest Envelope

  test "create an Envelope from Polygon" do
    geo = %Geo.Polygon{coordinates: [[{2, -2}, {20, -2}, {11, 11}, {2, -2}]]}

    assert Envelope.from_geo(geo) === %Envelope{min_x: 2, min_y: -2, max_x: 20, max_y: 11}
  end

  test "create an Envelope from a Point" do
    geo = %Geo.Point{coordinates: {2, -2}}

    assert Envelope.from_geo(geo) === %Envelope{min_x: 2, min_y: -2, max_x: 2, max_y: -2}
  end

  test "create and Envelope from a Point and radius" do
    env = Envelope.from_geo({2, -2})

    assert Envelope.expand_by(env, 3) === %Envelope{
             min_x: -1,
             min_y: -5,
             max_x: 5,
             max_y: 1
           }
  end

  test "create an Envelope from an empty Polygon" do
    assert Envelope.empty?(Envelope.from_geo(%Geo.Polygon{coordinates: [[]]}))
  end

  test "detect an empty Envelope" do
    assert Envelope.empty?(Envelope.empty())

    refute Envelope.empty?(
             Envelope.from_geo(%Geo.Polygon{coordinates: [[{2, -2}, {20, -2}, {11, 11}, {2, -2}]]})
           )
  end

  test "expand an envelope by a radius" do
    assert Envelope.empty?(Envelope.expand_by(Envelope.empty(), 4))

    assert Envelope.expand_by(
             Envelope.from_geo(%Geo.Polygon{coordinates: [[{2, -2}, {20, -2}, {11, 11}, {2, -2}]]}),
             3
           ) === %Envelope{min_x: -1, min_y: -5, max_x: 23, max_y: 14}
  end

  test "expand an envelope with a geometry" do
    env =
      Envelope.from_geo(%Geo.Polygon{coordinates: [[{2, -2}, {20, -2}, {11, 11}, {2, -2}]]})
      |> Envelope.expand(%Geo.Point{coordinates: {3, -5}})

    assert env === %Envelope{min_x: 2, min_y: -5, max_x: 20, max_y: 11}

    assert Envelope.expand(Envelope.empty(), %Geo.Point{coordinates: {3, -5}}) ===
             %Envelope{min_x: 3, min_y: -5, max_x: 3, max_y: -5}
  end
end
