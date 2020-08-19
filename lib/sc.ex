defmodule SC do
  @moduledoc """
  Elixir Erlang NIF versions of SuperCollider UGen plugins

  ## SuperCollider Plugins
  SC plugins uses NIFs for generating and transforming the frames in a
  similar way as SuperCollider (SC) uses UGens.
  SC "plugins" should implement the SC.Plugin behavior.

  ### Usage
  Before using any plugin it is important to initialize the Ctx from
  the application by calling SC.Ctx.put/1.

  """
end
