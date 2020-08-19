defmodule SC.Ctx do
  @moduledoc """
  ### Usage

  Before using any plugin it is important to initialize the Ctx from
  the application by calling SC.Ctx.put/1.

  """
  defstruct [:rate, :period_size]

  @type rates() :: 44100 | 48000 | 96000 | 192_000

  @typedoc """
  Ctx properties are:

  * `:rate` - Sample rate.
  * `:period_size` - Buffer size in number of samples.
  """
  @type t() :: %__MODULE__{
    rate: rates(),
    period_size: pos_integer()
  }

  @spec put(ctx :: t()) :: :ok
  def put(ctx = %__MODULE__{}) do
    :persistent_term.put(__MODULE__, ctx)
  end

  @spec get() :: t()
  def get() do
    :persistent_term.get(__MODULE__)
  end
end
