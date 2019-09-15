defmodule Satellite.Response do

  defstruct [code: 200, headers: [{<<"content-type">>, <<"text/html">>}], body: <<>>]

  @codes [{200, "OK"}, {404, "Not Found"}, {500, "Internal Server Error"}]
  
  def make_resp(
    %__MODULE__{
      code: code,
      headers: headers,
      body: body
    }
  ) do

    code_prep = make_code(code)
    headers_prep = map_headers(headers)
    {n_body, content_length_prep} = create_length(body)
    
    <<"HTTP/1.0 ", code_prep::binary, "\n", headers_prep::binary, content_length_prep::binary, "\n", n_body::binary>>
  end

  defp map_headers(headers), do: map_headers(headers, <<>>)
  defp map_headers([{header, value} | t], acc) do
    IO.inspect({header, value}, label: "header")
    map_headers(t, <<acc::binary, header::binary, ": ", value::binary, "\n">>)
  end
  defp map_headers([], acc), do: acc
  
  defp create_length(nil), do: {<<>>, <<"content-length: 0">>}
  defp create_length(<<>>), do: {<<>>, <<"content-length: 0">>}
  defp create_length(body) do
    size = :erlang.integer_to_binary(:erlang.size(body))
    {body, <<"content-length: ", size::binary, "\n">>}
  end


  Enum.each(@codes, fn({code, val}) ->
    
    string_v = Integer.to_string(code)
    atom_v = String.to_atom(string_v)

    defp make_code(unquote(code)), do: <<unquote(string_v)::binary, " ", unquote(val)::binary>>
    defp make_code(unquote(string_v)), do: <<unquote(string_v)::binary, " ", unquote(val)::binary>>
    defp make_code(unquote(atom_v)), do: <<unquote(string_v)::binary, " ", unquote(val)::binary>>

  end)

  def error_resp(body \\ "Internal Server Error") do
    %__MODULE__{code: 500, headers: [{<<"content-type">>, <<"text/html">>}], body: body}
  end

  def not_found(body \\ "Not Found") do
    %__MODULE__{code: 404, headers: [{<<"content-type">>, <<"text/html">>}], body: body}
  end
  
end
