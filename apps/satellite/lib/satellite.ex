defmodule Satellite do
  @behaviour :gen_statem

  alias Satellite.{Request, Response}
  
  defstruct [:socket, :config, :conn, :response, :router, pipeline: [], request: %Request{}]
  
  @impl true
  def callback_mode(), do: :handle_event_function
  
  def start_link(socket, opts) do
    :gen_statem.start_link(__MODULE__, {socket, opts}, [])
  end
  
  @impl true
  def init({socket, config}) do
    {:ok, :waiting,  %__MODULE__{socket: socket, config: config}, [{:next_event, :internal, :wait}]}
  end

  @impl true
  def handle_event(:internal, :wait, :waiting, %{socket: socket, config: %{router: router, pipeline: pipeline}} = data) do
    {:ok, conn} = :gen_tcp.accept(socket)
    
    :gen_tcp.controlling_process(conn, self())

    n_data = %{data | conn: conn, router: router, pipeline: pipeline, request: %Request{}}

    set_next_step(n_data, <<>>)
  end

  def handle_event(:internal, event, {:noread, _name, fun, acc}, %{request: request} = data) do
    case fun.(request, acc) do
      {:ok, n_request} ->
        set_next_step(%{data | request: n_request}, {:event, event})

      {:error, reason} ->
        response = Response.error_resp("#{inspect reason}")
        {:next_state, :response, %{data | response: response}, [{:next_event, :internal, :send_response}]}
    end
  end

  def handle_event(:internal, event, {:check, _name, fun, acc}, %{request: request} = data) do
    case fun.(request, acc) do
      {:next, n_request} ->
        set_next_step(%{data | request: n_request}, {:event, event})

      {:dispatch, n_request} ->
        {:next_state, :dispatching, %{data | request: n_request}, [{:next_event, :internal, :dispatch}]}

      {:response, response} ->
        {:next_state, :response, %{data | response: response}, [{:next_event, :internal, :send_response}]}

      {:error, reason} ->
        response = Response.error_resp("#{inspect reason}")
        {:next_state, :response, %{data | response: response}, [{:next_event, :internal, :send_response}]}
    end
  end

  def handle_event(:internal, :read, _, %{conn: conn} = data) do
    case :gen_tcp.recv(conn, 0, 1000) do
      {:ok, packet} ->
        IO.inspect(packet, label: "packet")
        {:keep_state_and_data, [{:next_event, :internal, {:parse, packet}}]}

      {:error, reason} ->
        response = Response.error_resp("#{inspect reason}")
        {:next_state, :response, %{data | response: response}, [{:next_event, :internal, :send_response}]}
    end
  end

  def handle_event(:internal, {:parse, packet}, {type, name, fun, acc}, %{request: request} = data) do

    case fun.(request, packet, acc) do
      {:cont, n_request, n_acc} ->
        IO.inspect({:cont, n_request, n_acc})
        {:next_state, {type, name, fun, n_acc}, %{data | request: n_request}, [{:next_event, :internal, :read}]}

      {:done, n_request, remaining} ->
        IO.inspect({:done, n_request, remaining})
        set_next_step(%{data | request: n_request}, remaining)

      {:error, reason} ->
        response = Response.error_resp("#{inspect reason}")
        {:next_state, :response, %{data | response: response}, [{:next_event, :internal, :send_response}]}
    end
    
  end

  def handle_event(:internal, :dispatch, :dispatching, %{request: request, conn: conn, router: router} = data) do
    try_dispatch(conn, router, request)
    {:next_state, :waiting, %{data | conn: nil}, [{:next_event, :internal, :wait}]} 
  end

  def handle_event(:internal, :send_response, :response, %{conn: conn, response: response} = data) do
    try_send_response(conn, response)
    {:next_state, :waiting, %{data | conn: nil}, [{:next_event, :internal, :wait}]}
  end

  def handle_event(:internal, :close, _, %{conn: conn} = data) do
    :gen_tcp.close(conn)
    {:next_state, :waiting, %{data | conn: nil}, [{:next_event, :internal, :wait}]}
  end


  defp set_next_step(%{pipeline: [h | t]} = data, remaining) do

    event = case remaining do
              <<>> -> :read
              {:event, event} -> event
              _ -> {:parse, remaining}
            end

    {:next_state, h, %{data | pipeline: t}, [{:next_event, :internal, event}]}
  end

  defp set_next_step(%{pipeline: []} = data, _remaining) do
    {:next_state, :dispatching, data, [{:next_event, :internal, :dispatch}]}
  end

  defp try_dispatch(conn, router, %{verb: verb, path: path, host: host} = request) do
    case apply(router, :route, [verb, path, host, request]) do
      response -> try_send_response(conn, response)
    end
  rescue
    e ->
      IO.inspect(e, label: "error try_dispatch")
      try_send_response(conn, Response.error_resp())
  end

  defp try_send_response(conn, %Response{} = response) do
    n_response = Response.make_resp(response)
    send_response(conn, n_response)
  after
    :gen_tcp.close(conn)
  end

  defp try_send_response(conn, response) when is_binary(response) do
    send_response(conn, response)
  after
    :gen_tcp.close(conn)
  end

  defp send_response(conn, response) do
    :gen_tcp.send(conn, response)
  end
end
