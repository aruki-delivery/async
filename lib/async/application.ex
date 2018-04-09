defmodule Async.Application do
    use Application
    require Logger

    def start(type, args) do
      Logger.info("#{__MODULE__}.start(#{inspect type}}, #{inspect args})...")

      #Logger.info("#{__MODULE__} starting :ok = Application.start(:async)")
      #{:ok, _} = Application.ensure_all_started(:async, :permanent)
      # TODO: figure out why Application.start / ensure... hangs
      Logger.info("#{__MODULE__} starting :async.start([], [])...")
      {:ok, async_pid} = :async.start([], [])
      Logger.info("#{__MODULE__} starting :async.start([], []) = #{inspect async_pid}")


      {:ok, async_sup} = Supervisor.start_link([Async], [strategy: :one_for_one, name: Async.Application.Supervisor])
      Logger.info("#{__MODULE__} started Async - #{inspect async_sup}")
      {:ok, async_sup}
    end
end
