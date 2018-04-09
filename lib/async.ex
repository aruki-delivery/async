defmodule Async do
  use Supervisor
  require Logger

  def run(f), do: :async.run(f)
  def run(q, f), do: :async.run(q, f)
  def run(m, f, a), do: :async.run(m, f, a)
  def run(q, m, f, a), do: :async.run(q, m, f, a)

  def start_default_queue(), do: :async.start_default_queue()
  def start_queue(q), do: :async.start_queue(q)
  def start_queue(q, o), do: :async.start_queue(q, o)
  def stop_queue(q), do: :async.stop_queue(q)
  def queue_list(), do: :async.queue_list()

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
