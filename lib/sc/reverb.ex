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
  @doc false
  # -----------------------------------------------------------

  defmodule FreeVerb do
    @behaviour SC.Plugin
    defstruct [:ref, mix: 0.33, room: 0.5, damp: 0.5]

    def new(mix \\ 0.33, room \\ 0.5, damp \\ 0.5) do
      %SC.Ctx{rate: rate, period_size: period_size} = SC.Ctx.get()
      %__MODULE__{ref: SC.Reverb.reverb_ctor(rate, period_size, :freeverb),
                  mix: mix, room: room, damp: damp}
    end

    def new2(mix \\ 0.33, room \\ 0.5, damp \\ 0.5) do
      %SC.Ctx{rate: rate, period_size: period_size} = SC.Ctx.get()
      %__MODULE__{ref: SC.Reverb.reverb_ctor(rate, period_size, :freeverb2),
                  mix: mix, room: room, damp: damp}
    end

    def ns(enum, mix \\ 0.33, room \\ 0.5, damp \\ 0.5) do
      stream(new(mix, room, damp), enum)
    end

    def ns2(enum, mix \\ 0.33, room \\ 0.5, damp \\ 0.5) do
      stream(new2(mix, room, damp), enum)
    end

    def next(%__MODULE__{ref: ref, mix: mix, room: room, damp: damp}, frames) do
      SC.Reverb.reverb_next(ref, frames, mix, room, damp)
    end

    def stream(m = %__MODULE__{mix: a}, enum) when is_float(a) do
      ls = Stream.unfold(a, fn x -> {x,x} end)
      stream(%{m | :mix => ls}, enum)
    end
    def stream(m = %__MODULE__{room: a}, enum) when is_float(a) do
      ls = Stream.unfold(a, fn x -> {x,x} end)
      stream(%{m | :room => ls}, enum)
    end
    def stream(m = %__MODULE__{damp: a}, enum) when is_float(a) do
      ls = Stream.unfold(a, fn x -> {x,x} end)
      stream(%{m | :damp => ls}, enum)
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
