defmodule Satellite.Path do

  def parse(ctx, <<>>, acc), do: {:cont, ctx, acc}
  def parse(ctx, <<?\s, rem::bits>>, {false, _, _} = acc), do: parse(ctx, rem, acc)

  def parse(ctx, <<?\s, rem::bits>>, {true, acc, prior}) do
    n_acc = maybe_add_prior(acc, prior)
    
    n_ctx = %{
      ctx |
      path: Enum.reverse(
        List.flatten(n_acc)
      )
    }

    {:done, n_ctx, rem}
  end

  def parse(%{query: q} = ctx, <<?\s, rem::bits>>, {:query, :value, key, value}) do
    {:done, %{ctx | query: Map.put(q, key, value)}, rem}
  end

  def parse(ctx, <<?\s, rem::bits>>, _), do: {:done, ctx, rem}

  def parse(ctx, <<?=, rem::bits>>, {:query, :key, key}) do
    parse(ctx, rem, {:query, :value, key, <<>>})
  end

  def parse(ctx, <<h, rem::bits>>, {:query, :key, key}) do
    parse(ctx, rem, {:query, :key, <<key::binary, h>>})
  end

  def parse(%{query: q} = ctx, <<?&, rem::bits>>, {:query, :value, key, value}) do
    parse(%{ctx | query: Map.put(q, key, value)}, rem, {:query, :key, <<>>})
  end

  def parse(ctx, <<h, rem::bits>>, {:query, :value, key, value}) do
    parse(ctx, rem, {:query, :value, key, <<value::binary, h>>})
  end

  def parse(ctx, <<?/, rem::bits>>, {_, acc, prior}) do
    n_acc = maybe_add_prior(acc, prior)
    parse(ctx, rem, {true, n_acc, <<>>})
  end

  def parse(ctx, <<??, rem::bits>>, {:true, acc, prior}) do
    n_acc = maybe_add_prior(acc, prior)
    n_ctx = %{
      ctx |
      path: Enum.reverse(
        List.flatten(n_acc)
      )
    }

    parse(n_ctx, rem, {:query, :key, <<>>})
  end

  def parse(ctx, <<h, rem::bits>>, {_, acc, prior}) do
    parse(ctx, rem, {true, acc, <<prior::binary, h>>})
  end

  def parse(_ctx, _, _), do: {:error, "Parsing path"}

  defp maybe_add_prior(acc, <<>>), do: acc
  defp maybe_add_prior(acc, prior), do: [prior | acc]
  
end
