defmodule Launchpad do
  @behaviour :gen_statem

  defstruct [:socket, :config, max_pool: 5, pool_count: 0, acceptors: %{}]

  alias Satellite.Configuration, as: Config


  defp set_defaults(config) do
    maybe_set_name(config)
    |> maybe_set_port()
    |> maybe_set_pipeline()
  end
  
  defp maybe_set_name(%Config{name: name} = config), do: maybe_set(:name, name, {:local, __MODULE__}, config)

  defp maybe_set_port(%Config{port: port} = config), do: maybe_set(:port, port, 4000, config)

  defp maybe_set_pipeline(%Config{pipeline: pipeline} = config), do: maybe_set(:pipeline, pipeline, Satellite.Defaults.default_pipeline(), config)

  defp maybe_set(key, nil, default, config), do: Map.put(config, key, default)
  defp maybe_set(_, _, _, config), do: config
    
  
  def start_link(%Config{} = config) do
    %{name: name} = ok_config = set_defaults(config)
    
    :gen_statem.start_link(name, __MODULE__, ok_config, [])
  end

  @impl true
  def callback_mode(), do: :handle_event_function

  @impl true
  def init(%{port: port} = config) do
    Process.flag(:trap_exit, true)
    
    {:ok, socket} = :gen_tcp.listen(port, [:binary, {:packet, :raw}, {:active, false}, {:reuseaddr, true}])

    data = %__MODULE__{socket: socket, config: config}
    
    {:ok, :starting, data, [{:next_event, :internal, :create_listener}]}
  end

  @impl true
  def handle_event(:internal, :create_listener, _state,
    %__MODULE__{
      socket: socket,
      config: config,
      max_pool: max,
      pool_count: pc,
      acceptors: acceptors
    } = data
  ) when pc < max do
    
    {:ok, pid} = Satellite.start_link(socket, Map.put(config, :number, pc))
    n_acceptors = Map.put(acceptors, pid, true)
    
    {:keep_state, %{data | pool_count: pc + 1, acceptors: n_acceptors}, [{:next_event, :internal, :create_listener}]}
  end

  def handle_event(:internal, :create_listener, :starting, data), do: {:next_state, :running, data, []}


  def handle_event(:internal, :create_listener, _state, _data), do: {:keep_state_and_data, []}

  def handle_event(:info, {:EXIT, pid, _reason}, _, %{pool_count: pc, acceptors: acceptors} = data) when :erlang.is_map_key(pid, acceptors) do
    
    {_, n_acceptors} = Map.pop(acceptors, pid)
    
    {:keep_state, %{data | pool_count: pc - 1, acceptors: n_acceptors}, [{:next_event, :internal, :create_listener}]}
  end

  def handle_event(:info, {:EXIT, pid, reason}, _, _data) do
    IO.puts("Received exit from unknown process #{inspect pid} with reason #{reason}")	
    {:keep_state_and_data, []}
  end

end
