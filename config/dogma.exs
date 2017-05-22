use Mix.Config
alias Dogma.Rule

config :dogma,
  override: [
    %Rule.LineLength{max_length: 150},
    %Rule.PipelineStart{enabled: false}
  ]
