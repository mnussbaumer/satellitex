# Satellitex

This is the final version of the code used in the tutorial on how to [build the basis of an HTML server in Elixir](https://mnussbaumer.github.io/programming/elixir/2019/09/14/a-basic-http-server-in-elixir.html)

Add to your mix.exs file:

```elixir
defp deps do
    [
      {:satellitex, path: "../satellitex"}
    ]
end
```

And create a router module:

```elixir
defmodule Router do
  use Satellite.Routing

  route "get", "/", Controller, :test
  route "get", "/:any/oi/:some", Controller, :test2, "*"
  route "get", "*", Controller, :test3
  route "post", "/data", Controller, :test4
end
```

And a controller module:

```elixir
defmodule Controller do

  def test(request) do
    %Satellite.Response{body: "#{inspect request}"}
    |> Satellite.Response.make_resp()
  end

  def test2(request) do
    %Satellite.Response{body: "#{inspect request}"}
    |> Satellite.Response.make_resp()
  end

  def test3(request) do
    %Satellite.Response{body: """
    <html><body><h1>Wildcard match!</h1><br><br><div style="color: red;">#{inspect request}</div></body></html>
    """}
    |> Satellite.Response.make_resp()
  end

  def test4(%{body: parsed_body}) do
    response_body = "Parsed: " <> Jason.encode!(parsed_body) <> "\n"
    %Satellite.Response{body: response_body, headers: [{<<"content-type">>, <<"application/json">>}]}
    |> Satellite.Response.make_resp()
  end

end
```

Edit your `application.ex` file to:

```elixir
defmodule TestSatellitex.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      # other stuff
      Supervisor.child_spec(%{id: Server1, start: {Launchpad, :start_link, [%Satellite.Configuration{router: Router}]}}, type: :worker)
    ]

    opts = [strategy: :one_for_one, name: TestSatellitex.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
```

And run `iex -S mix run` to start a server on port 4000. Refer to the tutorial for an in-depth walk-through.


