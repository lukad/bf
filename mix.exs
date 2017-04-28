defmodule Bf.Mixfile do
  use Mix.Project

  def project do
    [
      app: :bf,
      version: "0.1.0",
      elixir: "~> 1.3",
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod,
      deps: deps(),
      escript: [main_module: Bf.CLI]
    ]
  end

  def deps do
    [{:optimus, "~> 0.1.0", runtime: false}]
  end
end
