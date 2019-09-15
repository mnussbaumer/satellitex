defmodule Satellite.Request do

  defstruct [
    :verb,
    :host,
    :protocol,
    :version,
    :accept,
    :body,
    path: [],
    query: %{},
    headers: %{},
    finished_headers: false,
    halt: false,
    params: %{}
  ]
  
end
