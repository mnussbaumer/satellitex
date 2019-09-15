defmodule Satellite.Body do

  def parse(%{verb: :post, headers: headers} = request, rem, {count, acc}) do
    n_size = count + :erlang.size(rem)
    case headers do
      %{<<"content-length">> => 0} -> {:done, request, <<>>}
      %{<<"content-length">> => ^n_size} ->
        case parse_content(headers, rem) do
          {:ok, decoded} -> {:done, %{request | body: decoded}, <<>>}
          {:error, error} -> {:error, error}
        end
      _ ->
        {:cont, request, {n_size, <<acc::bits, rem::bits>>}}
    end
  end

  def parse(request, _, _), do: {:done, request, <<>>}

  def parse_content(%{<<"content-type">> => <<"application/json">>}, rem) do
    Jason.decode(rem)
  catch e ->
      IO.inspect(e, label: "error")
    {:error, e}
  end
  
end
