defmodule Satellite.Routing do


  defmacro __using__(_opts) do
    quote do
      import Satellite.Routing
      @before_compile Satellite.Routing
    end
  end

  defmacro route(verb, path, module, function, domain \\ "*") do

    verb_atom = String.to_atom(String.downcase(verb))
    {path_splitted, vars} = split_path(path)
    {domain_splitted, domain_vars} = split_domain(domain)
    all_vars = vars ++ domain_vars
    
    quote do
      def route(unquote(verb_atom), unquote(path_splitted), unquote(domain_splitted), %{params: params} = request) do
        ctx = %{
          request |
          params: Enum.reduce(unquote(all_vars), params, fn({key, var}, acc) ->
            Map.put(acc, key, Macro.escape(var))
          end)
        }
        
        apply(unquote(module), unquote(function), [ctx])
      end
    end
  end

  defp split_path(path) do
    case String.split(path, "/", trim: true) do
      ["*"] -> {(quote do: _), []}
      
      split ->
          Enum.reduce(split, {[], []}, fn
            ("*", {acc1, acc2}) ->
              {[(quote do: _) | acc1], acc2}
            
            (<<?:, rem::binary>>, {acc1, acc2}) ->
              {[Macro.var(String.to_atom(rem), nil) | acc1], [{String.to_atom(rem), Macro.var(String.to_atom(rem), nil)} | acc2]}
            
            (other, {acc1, acc2}) ->
              {[other | acc1], acc2}
            
          end)
          |> case do
               {paths, vars} -> {Enum.reverse(paths), Enum.reverse(vars)}
             end
    end
  end

  defp split_domain(domain) do
    case String.split(domain, ".", trim: true) do
      ["*"] -> {(quote do: _), []}
      
      [<<?:, rem::binary>>] ->
          host_var = String.to_atom("host_#{rem}")
          {Macro.var(host_var, nil), [{host_var, Macro.var(host_var, nil)}]}

        split ->
        Enum.reduce(split, {[], []}, fn
          ("*", {acc1, acc2}) ->
            {[(quote do: _) | acc1], acc2}

          (<<?\\, rem::binary>>, {acc1, acc2}) -> {[rem | acc1], acc2}
          
          (<<?:, rem::binary>>, {acc1, acc2}) ->
            host_var = String.to_atom("host_#{rem}")
            {[Macro.var(host_var, nil) | acc1], [{host_var, Macro.var(host_var, nil)} | acc2]}
          
          (other, {acc1, acc2}) ->
            {[other | acc1], acc2}
          
        end)
        |> case do
             {paths, vars} -> {Enum.reverse(paths), Enum.reverse(vars)}
           end
    end
  end


  defmacro __before_compile__(_env) do
    quote do
      def route(_, _, _, _ctx), do: Satellite.Response.not_found()
    end
  end
end
