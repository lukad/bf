use Mix.Config
alias Dogma.Rule

config :dogma,
  override: [%Rule.PipelineStart{enabled: false}]
