defmodule SC.Reverb do


  # -----------------------------------------------------------
  @on_load :load_nifs

  @doc false
  def load_nifs do
    case :erlang.load_nif(:code.priv_dir(:sc_plugin_nifs) ++ '/sc_reverb', 0) do
      :ok -> :ok
      {:error, {:reload, _}} -> :ok
      {:error, reason} ->
        :logger.warning('Failed to load sc_reverb NIF: ~p',[reason])
    end
  end

  @doc false
  def reverb_ctor(_rate, _level, _type), do: raise "NIF ramp_ctor/3 not loaded"
  @doc false
  def reverb_next(_ref, _frames, _mix, _room, _damp), do: raise "NIF ramp_next/5 not loaded"

  # -----------------------------------------------------------

  defmodule FreeVerb do
    @behaviour SC.Plugin
    @moduledoc """
    ### FreeVerb plugin

    The SC.Reverb.FreeVerb module instances one and two channel
    Reverb streams.

    """
    @typedoc "A float or a stream of floats"
    @type par() :: float() | Enumerable.t()

    defstruct [:ref, mix: 0.33, room: 0.5, damp: 0.5]
    @typedoc """
    Properties that can be set for FreeVerb.

    Available options are:
    * `:mix` - dry/wet balance. range 0..1.
    * `:room` - room size. rage 0..1.
    * `:damp` - Reverb HF damp. range 0..1.
    """
    @type t() :: %__MODULE__{
      ref: reference(),
      mix: par(),
      room: par(),
      damp: par()
    }

    @doc "Create one channel FreeVerb filter"
    @spec new(mix :: par, room :: par, damp :: par) :: t
    def new(mix \\ 0.33, room \\ 0.5, damp \\ 0.5) do
      %SC.Ctx{rate: rate, period_size: period_size} = SC.Ctx.get()
      %__MODULE__{ref: SC.Reverb.reverb_ctor(rate, period_size, :freeverb),
                  mix: mix, room: room, damp: damp}
    end

    @doc "Create two channel FreeVerb filter (FreeVerb2)"
    @spec new2(mix :: par, room :: par, damp :: par) :: t
    def new2(mix \\ 0.33, room \\ 0.5, damp \\ 0.5) do
      %SC.Ctx{rate: rate, period_size: period_size} = SC.Ctx.get()
      %__MODULE__{ref: SC.Reverb.reverb_ctor(rate, period_size, :freeverb2),
                  mix: mix, room: room, damp: damp}
    end

    @doc "Create one channel FreeVerb filter stream"
    @spec ns(enum :: Enumerable.t, mix :: par, room :: par, damp :: par) :: Enumerable.t
    def ns(enum, mix \\ 0.33, room \\ 0.5, damp \\ 0.5) do
      stream(new(mix, room, damp), enum)
    end

    @doc "Create two channel FreeVerb filter (FreeVerb2) stream"
    @spec ns2(enum :: Enumerable.t, mix :: par, room :: par, damp :: par) :: Enumerable.t
    def ns2(enum, mix \\ 0.33, room \\ 0.5, damp \\ 0.5) do
      stream(new2(mix, room, damp), enum)
    end

    @spec next(freeverb :: t(), frames :: binary()) :: binary()
    def next(%__MODULE__{ref: ref, mix: mix, room: room, damp: damp}, frames) do
      SC.Reverb.reverb_next(ref, frames, mix, room, damp)
    end

    @spec stream(freeverb :: t(), enum :: Enumerable.t()) :: Enumerable.t()
    def stream(freeverb = %__MODULE__{mix: a}, enum) when is_float(a) do
      ls = Stream.unfold(a, fn x -> {x,x} end)
      stream(%{freeverb | :mix => ls}, enum)
    end
    def stream(freeverb = %__MODULE__{room: a}, enum) when is_float(a) do
      ls = Stream.unfold(a, fn x -> {x,x} end)
      stream(%{freeverb | :room => ls}, enum)
    end
    def stream(freeverb = %__MODULE__{damp: a}, enum) when is_float(a) do
      ls = Stream.unfold(a, fn x -> {x,x} end)
      stream(%{freeverb | :damp => ls}, enum)
    end
    def stream(%__MODULE__{ref: ref, mix: mix, room: room, damp: damp}, enum) do
      Stream.zip([enum, mix, room, damp])
      |> Stream.map(fn
        {frames, mixf, roomf, dampf} when is_list(frames) ->
          SC.Reverb.reverb_next(ref, frames, mixf, roomf, dampf)
      {frames, mixf, roomf, dampf} ->
          SC.Reverb.reverb_next(ref, [frames], mixf, roomf, dampf)
      end)
    end
  end

end
