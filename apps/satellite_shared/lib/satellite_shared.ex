defmodule Satellite.Shared do

  use Bitwise, only_operators: true
  
  Enum.each(?A..?Z, fn(value) ->
    downcased = value ^^^ 32
    def downcase(unquote(value)), do: unquote(downcased)
  end)

  def downcase(val), do: val
end
