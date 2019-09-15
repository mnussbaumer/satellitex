defmodule Satellite.Verb do

  def parse(ctx, rem, <<"GET">>), do: {:done, %{ctx | verb: :get}, rem}

  def parse(ctx, rem, <<"POST">>), do: {:done, %{ctx | verb: :post}, rem}

  def parse(ctx, <<>>, acc), do: {:cont, ctx, acc}

  def parse(ctx, <<?\s, rem::bits>>, acc), do: parse(ctx, rem, acc)

  def parse(ctx, <<h, rem::bits>>, acc), do: parse(ctx, rem, <<acc::binary, h>>)

  def parse(_ctx, _, _), do: {:error, "Parsing Verb"}
  
end
