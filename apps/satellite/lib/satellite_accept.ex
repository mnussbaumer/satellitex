defmodule Satellite.Accept do

  def set(%{headers: headers} = ctx, _) do
    {:ok, %{ctx | accept: extract_accept(headers)}}
  end

  def extract_accept(%{"accept" => <<"application/json", _::bits>>}), do: :json
  def extract_accept(%{"accept" => <<"text/html", _::bits>>}), do: :html
  def extract_accept(_), do: :any
    
end
