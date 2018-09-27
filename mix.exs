defmodule Bf.Mixfile do
  use Mix.Project

  def project do
    [
      app: :bf,
      version: "1.2.0",
      elixir: "~> 1.3",
      description: description(),
      package: package(),
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      escript: [main_module: Bf.CLI],

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

  defp deps do
    [
      {:combine, "~> 0.9.6"},
      {:optimus, "~> 0.1.0", runtime: false},
      {:ex_doc, "~> 0.19", only: :dev, runtime: false}
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
