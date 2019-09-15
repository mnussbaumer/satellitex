defmodule Satellite.Host do

  import Satellite.Shared, only: [downcase: 1]

  def set(%{headers: headers} = ctx, _) do
    host = Map.get(headers, "host", "")
    {:ok, %{ctx | host: split_host(host)}}
  end

  def split_host(val), do: split_host(val, <<>>, [])
  def split_host(<<>>, segment, acc), do: Enum.reverse([segment | acc])
  def split_host(<<?., rem::bits>>, segment, acc), do: split_host(rem, <<>>, [segment | acc])
  def split_host(<<?:, _::bits>>, segment, acc), do: Enum.reverse([segment | acc])
  def split_host(<<h, rem::bits>>, segment, acc) do
    n_h = downcase(h)
    split_host(rem, <<segment::binary, n_h>>, acc)
  end

  def split_host(_, _, _), do: []
end
