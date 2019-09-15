defmodule Satellite.Headers do

  import Satellite.Shared, only: [downcase: 1]

  def parse(ctx, <<>>, acc), do: {:cont, ctx, acc}
  def parse(ctx, <<?:, rem::bits>>, {:header, key}), do: parse(ctx, rem, {:value, key, <<>>})
  def parse(ctx, <<?\s, rem::bits>>, {:header, key}), do: parse(ctx, rem, {:header, key})
  def parse(ctx, <<?\s, rem::bits>>, {:value, key, acc}), do: parse(ctx, rem, {:value, key, acc})

  def parse(ctx, <<h, rem::bits>>, {:header, key}) do
    n_h = downcase(h)
    parse(ctx, rem, {:header, <<key::binary, n_h>>})
  end

  def parse(ctx, <<?\r, rem::bits>>, {:header, _}) do
    parse(ctx, rem, {:in_termination, <<?\r>>})
  end

  def parse(ctx, <<?\n, rem::bits>>, {:in_termination, <<?\r>>}) do
    parse(ctx, rem, {:in_termination, <<?\r,?\n>>})
  end

  def parse(ctx, <<?\r, rem::bits>>, {:in_termination, <<?\r, ?\n>>}) do
    parse(ctx, rem, {:in_termination, <<?\r,?\n,?\r>>})
  end

  def parse(ctx, <<?\n, rem::bits>>, {:in_termination, <<?\r, ?\n, ?\r>>}) do
    {:done, %{ctx | finished_headers: true}, rem}
  end

  def parse(ctx, <<h, rem::bits>>, {:in_termination, <<?\r, ?\n>>}) do
    n_h = downcase(h)
    parse(ctx, rem, {:header, <<n_h>>})
  end

  def parse(%{headers: headers} = ctx, <<?\r, rem::bits>>, {:value, key, acc}) do
    value = translate_header_content(key, acc)
    n_ctx = %{ctx | headers: Map.put(headers, key, value)}
    parse(n_ctx, rem, {:in_termination, <<?\r>>})
  end


  def parse(ctx, <<h, rem::bits>>, {:value, key, acc}) do

    n_h = case downcased_header?(key) do
            true -> downcase(h)
            _ -> h
          end
    
    parse(ctx, rem, {:value, key, <<acc::binary, n_h>>})
  end

  def parse(_ctx, _, _), do: {:error, "Parsing headers"}

  def translate_header_content(<<"content-length">>, val) when is_binary(val) do
    :erlang.binary_to_integer(val)  
    catch _ -> 0
  end

  def translate_header_content(_, val), do: val


  def downcased_header?(<<"content-type">>), do: true
  def downcased_header?(<<"accept">>), do: true
  def downcased_header?(_), do: false
end
