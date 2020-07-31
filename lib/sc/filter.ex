defmodule SC.Filter do


  # -----------------------------------------------------------
  @on_load :load_nifs

  @doc false
  def load_nifs do
    case :erlang.load_nif(:code.priv_dir(:sc_plugin_nifs) ++ '/sc_filter', 0) do
      :ok -> :ok
      {:error, {:reload, _}} -> :ok
      {:error, reason} ->
        :logger.warning('Failed to load sc_filter NIF: ~p',[reason])
    end
  end

  @doc false
  def ramp_ctor(_rate, _level), do: raise "NIF ramp_ctor/2 not loaded"
  @doc false
  def ramp_next(_ref, _frames, _lagtime), do: raise "NIF ramp_next/3 not loaded"
  @doc false

  def lag_ctor(_rate, _period_size), do: raise "NIF lag_ctor/2 not loaded"
  @doc false
  def lag_next(_ref, _frames, _lag), do: raise "NIF lag_next/3 not loaded"

  def lagud_ctor(_rate, _period_size), do: raise "NIF lagud_ctor/2 not loaded"
  @doc false
  def lagud_next(_ref, _frames, _lagup, _lagdown), do: raise "NIF lagud_next/4 not loaded"

  def lhpf_ctor(_rate, _period_size, _type ), do: raise "NIF lpf_ctor/3 not loaded"
  @doc false
  def lhpf_next(_ref, _frames, _freq), do: raise "NIF lpf_next/3 not loaded"

  @doc false
  def lhpf_next(_ref, _frames, _freq, _bw), do: raise "NIF lpf_next/4 not loaded"
  # -----------------------------------------------------------
  # Break a continuous signal into linearly interpolated segments
  # with specific durations.
  defmodule Ramp do
    @behaviour SC.Plugin
    defstruct [:ref, lagTime: 0.1]

    def new(lagtime \\ 0.1) do
      %SC.Ctx{rate: rate, period_size: period_size} = SC.Ctx.get()
      %__MODULE__{ref: SC.Filter.ramp_ctor(rate, period_size), lagTime: lagtime}
    end

    def ns(enum, lagtime \\ 0.1), do: stream(new(lagtime), enum)

    def next(%__MODULE__{ref: ref, lagTime: lagtime}, frames) when is_float(lagtime) do
      SC.Filter.ramp_next(ref, frames, lagtime)
    end

    def stream(m = %__MODULE__{lagTime: lagtime}, enum) when is_float(lagtime) do
      ls = Stream.unfold(lagtime, fn x -> {x,x} end)
      stream(%{m | :lagTime => ls}, enum)
    end
    def stream(%__MODULE__{ref: ref, lagTime: lagtime}, enum) do
      Stream.zip(enum, lagtime)
      |> Stream.map(fn {frames, lagtimef} -> SC.Filter.ramp_next(ref, frames, lagtimef) end)
    end
  end

  # -----------------------------------------------------------

  defmodule Lag do
    @behaviour SC.Plugin
    defstruct [:ref, lagTime: 0.1]

    def new(lagtime \\ 0.1) do
      %SC.Ctx{rate: rate, period_size: period_size} = SC.Ctx.get()
      %__MODULE__{ref: SC.Filter.lag_ctor(rate, period_size), lagTime: lagtime}
    end

    def ns(enum, lagtime \\ 0.1), do: stream(new(lagtime), enum)

    def next(%__MODULE__{ref: ref, lagTime: lagtime}, frames) when is_float(lagtime) do
      SC.Filter.lag_next(ref, frames, lagtime)
    end

    def stream(m = %__MODULE__{lagTime: lagtime}, enum) when is_float(lagtime) do
      ls = Stream.unfold(lagtime, fn x -> {x,x} end)
      stream(%{m | :lagTime => ls}, enum)
    end
    def stream(%__MODULE__{ref: ref, lagTime: lagtime}, enum) do
      Stream.zip(enum, lagtime)
      |> Stream.map(fn {frames, lagtimef} -> SC.Filter.lag_next(ref, frames, lagtimef) end)
    end
  end

  # -----------------------------------------------------------

  defmodule LagUD do
    @behaviour SC.Plugin
    defstruct [:ref, lagTimeU: 0.1, lagTimeD: 0.1]

    def new(lagtime_u \\ 0.1, lagtime_d \\ 0.1) do
      %SC.Ctx{rate: rate, period_size: period_size} = SC.Ctx.get()
      %__MODULE__{ref: SC.Filter.lagud_ctor(rate, period_size),
                  lagTimeU: lagtime_u, lagTimeD: lagtime_d}
    end

    def ns(enum, lu \\ 0.1, ld \\ 0.1), do: stream(new(lu, ld), enum)

    def next(%__MODULE__{ref: ref, lagTimeU: lagtime_u, lagTimeD: lagtime_d}, frames)
    when is_float(lagtime_u) and is_float(lagtime_d) do
      SC.Filter.lagud_next(ref, frames, lagtime_u, lagtime_d)
    end

    def stream(m = %__MODULE__{lagTimeU: lagtime_u}, enum) when is_number(lagtime_u) do
      ls = Stream.unfold(lagtime_u * 1.0, fn x -> {x,x} end)
      stream(%{m | :lagTime => ls}, enum)
    end
    def stream(m = %__MODULE__{lagTimeD: lagtime_d}, enum) when is_number(lagtime_d) do
      ls = Stream.unfold(lagtime_d * 1.0, fn x -> {x,x} end)
      stream(%{m | :lagTime => ls}, enum)
    end
    def stream(%__MODULE__{ref: ref, lagTimeU: lagtime_u, lagTimeD: lagtime_d}, enum) do
      Stream.zip([enum, lagtime_u, lagtime_d])
      |> Stream.map(
      fn {frames, lagtimeuf, lagtimedf} ->
        SC.Filter.lagud_next(ref, frames, lagtimeuf, lagtimedf)
      end)
    end
  end

  # -----------------------------------------------------------

  for {mod, type} <- [{SC.Filter.LPF, :lpf}, {SC.Filter.HPF, :hpf}] do
    defmodule mod do
      @behaviour SC.Plugin
      defstruct [:ref, frequency: 440.0]

      def new(frequency \\ 440.0) do
        %SC.Ctx{rate: rate, period_size: period_size} = SC.Ctx.get()
        %unquote(mod){ref: SC.Filter.lhpf_ctor(rate, period_size, unquote(type)),
                    frequency: frequency}
      end

      def ns(enum, frequency \\ 440.0), do: stream(new(frequency), enum)

      def next(%unquote(mod){ref: ref, frequency: frequency}, frames) when is_number(frequency) do
        SC.Filter.lhpf_next(ref, frames, frequency * 1.0)
      end

      def stream(m = %unquote(mod){frequency: frequency}, enum) when is_number(frequency) do
        fs = Stream.unfold(frequency, fn x -> {x,x} end)
        stream(%{m | :frequency => fs}, enum)
      end
      def stream(%unquote(mod){ref: ref, frequency: frequency}, enum) do
        Stream.zip(enum, frequency)
        |> Stream.map(fn {frames, frequencyf} -> SC.Filter.lhpf_next(ref, frames, frequencyf * 1.0) end)
      end
    end
  end

  for {mod, type} <- [{SC.Filter.BPF, :bpf}, {SC.Filter.BRF, :brf}] do
    defmodule mod do
      @behaviour SC.Plugin
      defstruct [:ref, frequency: 440.0, bwr: 1.0]
      @type t() :: %__MODULE__{
        ref: reference(),
        frequency: float(),
        bwr: float()
      }

      @typedoc """
      Centre frequency in Hertz.
      WARNING: due to the nature of its implementation frequency values
      close to 0 may cause glitches and/or extremely loud audio artifacts!
      """
      @type frequency() :: float()

      @typedoc """
      Bandwidth ratio. The reciprocal of Q.
      Q is conventionally defined as centerFreq / bandwidth,
      meaning bwr = (bandwidth / centerFreq).
      """
      @type bwr() :: float()

      def new(frequency \\ 440.0, bwr \\ 1.0 ) do
        %SC.Ctx{rate: rate, period_size: period_size} = SC.Ctx.get()
        %unquote(mod){ref: SC.Filter.lhpf_ctor(rate, period_size, unquote(type)),
                    frequency: frequency, bwr: bwr}
      end

      def ns(enum, frequency \\ 440.0, bwr \\ 1.0), do: stream(new(frequency, bwr), enum)

      def next(%unquote(mod){ref: ref, frequency: frequency, bwr: bwr}, frames) when is_number(frequency) do
        SC.Filter.lhpf_next(ref, frames, frequency * 1.0, bwr)
      end

      def stream(m = %unquote(mod){frequency: frequency}, enum) when is_number(frequency) do
        fs = Stream.unfold(frequency, fn x -> {x,x} end)
        stream(%{m | :frequency => fs}, enum)
      end
      def stream(m = %unquote(mod){bwr: bwr}, enum) when is_number(bwr) do
        bwrs = Stream.unfold(bwr, fn x -> {x,x} end)
        stream(%{m | :bwr => bwrs}, enum)
      end
      def stream(%unquote(mod){ref: ref, frequency: frequency, bwr: bwr}, enum) do
        Stream.zip([enum, frequency, bwr])
        |> Stream.map(fn {frames, frequencyf, bwrf} -> SC.Filter.lhpf_next(ref, frames, frequencyf * 1.0, bwrf * 1.0) end)
      end
    end
  end

end
