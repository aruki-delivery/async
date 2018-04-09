defmodule Async do
  use Supervisor
  require Logger


  def start_link(state) do
    Logger.info("#{__MODULE__}.start_link(#{inspect state})...")

    Logger.info("#{__MODULE__} starting {:ok, _} = Application.ensure_all_started(:async, :permanent)")
    {:ok, _} = Application.ensure_all_started(:async, :permanent)

    children = []
    {:ok, super_pid} = Supervisor.start_link(children, [strategy: :one_for_one, name: Async.Supervisor])
    Logger.info("#{__MODULE__} started: #{inspect super_pid}")
    {:ok, super_pid}
  end

  def init(state) do
    {:ok, state}
  end
end
