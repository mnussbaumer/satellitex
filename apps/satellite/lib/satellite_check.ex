defmodule Satellite.Check do

  def check(%{verb: :get} = ctx, _), do: {:dispatch, ctx}
  def check(%{verb: :post} = ctx, _), do: {:next, ctx}
  def check(ctx, _), do: {:dispatch, ctx}
end
