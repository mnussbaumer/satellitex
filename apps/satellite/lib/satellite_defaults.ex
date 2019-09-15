defmodule Satellite.Defaults do
  
  def default_pipeline() do
    [
      {:read, :verb, &Satellite.Verb.parse/3, <<>>},
      {:read, :path, &Satellite.Path.parse/3, {false, [], <<>>}},
      {:read, :conn, &Satellite.Conn.parse/3, <<>>},
      {:read, :headers, &Satellite.Headers.parse/3, {:header, <<>>}},
      {:noread, :host, &Satellite.Host.set/2, nil},
      {:noread, :accept, &Satellite.Accept.set/2, nil},
      {:check, :check_request_type, &Satellite.Check.check/2, nil},
      {:read, :body, &Satellite.Body.parse/3, {0, <<>>}}
    ]
  end
  
end
