# New Relic Tesla

[![Hex.pm Version](https://img.shields.io/hexpm/v/new_relic_tesla.svg)](https://hex.pm/packages/new_relic_tesla)

This package adds `Tesla` specific instrumentation on top of the `new_relic_agent` package. You may use all the built-in capabilities of the New Relic Agent!

Check out the agent for more:

* https://github.com/newrelic/elixir_agent
* https://hexdocs.pm/new_relic_agent

## Installation

Install the [Hex package](https://hex.pm/packages/new_relic_tesla)

```elixir
defp deps do
  [
    {:tesla, "~> 1.1"},
    {:new_relic_tesla, "~> 0.1"}
  ]
end
```

## Configuration

* You must configure `new_relic_agent` to authenticate to New Relic. Please see: https://github.com/newrelic/elixir_agent/#configuration

## Instrumentation

1) Add the Tesla Genserver to your supervisor tree

```elixir
defmodule MyApp.Application do
  @moduledoc false

  use Application
  def start(_type, args) do

    extra_children = Keyword.get(args, :extra_children, [])

    # List all child processes to be supervised
    children = [
      MyApp.Repo,
      NewRelicTesla.Telemetry.Tesla,
      ...
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Supervisor]
    Supervisor.start_link(children ++ extra_children, opts)
  end
end
```

2) Add the telemetry plug to your Tesla client

```elixir
  use Tesla

  plug Tesla.Middleware.Telemetry
  plug Tesla.Middleware.JSON
```
