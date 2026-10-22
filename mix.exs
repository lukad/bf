defmodule Bf.Mixfile do
  use Mix.Project

  def project do
    [
      app: :bf,
      version: "1.4.0",
      elixir: "~> 1.15",
      description: description(),
      package: package(),
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      elixirc_paths: elixirc_paths(Mix.env()),
      escript: [main_module: Bf.CLI, emu_args: "-kernel standard_io_encoding latin1"],

      # docs
      name: "bf",
      source_url: "https://github.com/lukad/bf",
      homepage_url: "https://github.com/lukad/bf",
      docs: [
        main: "readme",
        extras: ["README.md"]
      ]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:git_ops, "~> 2.0", only: [:dev], runtime: false},
      {:benchee, "~> 1.5", only: :dev},
      {:optimus, "~> 0.6", runtime: false, optional: true},
      {:ex_doc, "~> 0.40", only: :dev, runtime: false},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false}
    ]
  end

  defp description do
    "bf is a simple Brainfuck interpreter written in Elixir."
  end

  def package do
    [
      name: :bf,
      maintainers: ["Luka Dornhecker"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/lukad/bf"}
    ]
  end
end
