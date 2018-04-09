defmodule Async do
  use GenServer
  require Logger


  def start_link(state) do
    import Supervisor.Spec
    Logger.info("#{__MODULE__}.start_link(#{inspect state})...")
    Logger.info("#{__MODULE__} starting :async_sup...")
    children = [supervisor(:async, []),]
    {:ok, super_pid} = Supervisor.start_link(children, [strategy: :one_for_one, name: Async.Supervisor])
    Logger.info("#{__MODULE__} started :async_sup: #{inspect super_pid}")
    {:ok, super_pid}
  end

  def init(state) do
    {:ok, state}
  end
end
