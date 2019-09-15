defmodule Satellite.Configuration do

  @enforce_keys [:router]
  
  defstruct [
    :pipeline,
    :name,
    :router,
    port: 4000,
    acceptors: 5,
    max_size: 50_000,
    keep_full_request: false
  ]

end
