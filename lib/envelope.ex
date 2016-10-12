defmodule Envelope do
  defstruct min_x: 0, min_y: 0, max_x: 0, max_y: 0


  def from_geo(%Geo.Point{coordinates: {x, y}}) do
    %Envelope{min_x: x, min_y: y, max_x: x, max_y: y}
  end

  def from_geo(%{coordinates: coordinates}) do
    List.flatten(coordinates) |> build_env
  end

  def from_point_radius({x, y}, radius) when is_number(radius) and radius >= 0 do
    %Envelope{min_x: x, min_y: y, max_x: x, max_y: y}
    |> expand(radius)
  end

  def empty, do: %Envelope{min_x: nil, min_y: nil, max_x: nil, max_y: nil}
  def empty?(%Envelope{min_x: nil, min_y: nil, max_x: nil, max_y: nil}), do: true
  def empty?(%Envelope{}), do: false

  def expand(%Envelope{} = env, {x, y}) do
    case Envelope.empty? env do
      true  -> %Envelope{min_x: x, min_y: y, max_x: x, max_y: y}
      false -> %Envelope{
                  min_x: min(x, env.min_x),
                  min_y: min(y, env.min_y),
                  max_x: max(x, env.max_x),
                  max_y: max(y, env.max_y)
                }
    end
  end

  def expand(%Envelope{} = env, radius) when is_number(radius) and radius >= 0 do
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

  defp build_env([]), do: Envelope.empty
  defp build_env([{x, y} | rest]), do: expand(build_env(rest), {x, y})
end
