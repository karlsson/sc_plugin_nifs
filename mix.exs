defmodule SC.MixProject do
  use Mix.Project

  def project do
    [
      app: :sc_plugin_nifs,
      make_cwd: "c_src",
      make_clean: ["clean"],
      compilers: [:elixir_make] ++ Mix.compilers(),
      version: "0.1.0",
      elixir: "~> 1.9",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: description(),
      package: package(),
      # Docs
      name: "SC",
      source_url: "https://github.com/karlsson/sc_plugin_nifs",
      docs: [
        main: "SC",
        extras: ["README.md"]
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ex_doc, "~> 0.22", only: :dev, runtime: false},
      {:elixir_make, "~> 0.6", runtime: false}
    ]
  end

  defp description do
     "SuperCollider plugins converted to Erlang NIFs with Elixir API"
  end

  defp package do
    [
      maintainers: ["Mikael Karlsson"],
      licenses: ["GNU General Public License v3.0"],
      links: %{"GitHub" => "https://github.com/karlsson/sc_plugin_nifs"}
    ]
  end
end
