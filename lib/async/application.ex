defmodule Async.Application do
    use Application
    require Logger

    def start(type, args) do
      Logger.info("#{__MODULE__}.start(#{inspect type}}, #{inspect args})...")
      {:ok, async_sup} = Supervisor.start_link([Async], [strategy: :one_for_one, name: Async.Application.Supervisor])
      Logger.info("#{__MODULE__} started Async - #{inspect async_sup}")
      {:ok, async_sup}
    end
end
