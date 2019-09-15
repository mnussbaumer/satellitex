defmodule Satellite.Conn do

  def parse(ctx, rem, <<"HTTP/1.1", ?\r, ?\n>>), do: {:done, %{ctx | version: {1, 1}}, rem}
  def parse(ctx, rem, <<"HTTP/1.0", ?\r, ?\n>>), do: {:done, %{ctx | version: {1, 0}}, rem}

  def parse(ctx, <<>>, acc), do: {:cont, ctx, acc}

  def parse(ctx, <<?\s, rem::bits>>, acc), do: parse(ctx, rem, acc)
  def parse(ctx, <<h, rem::bits>>, acc), do: parse(ctx, rem, <<acc::binary, h>>)

  def parse(ctx, _, _), do: {:error, "Parsing Conn"}
end
