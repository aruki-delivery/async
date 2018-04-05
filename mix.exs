defmodule Async.Mixfile do
  use Mix.Project

  def project do
    [app: :async,
      version: "0.1.0",
      language: :erlang,
      deps: deps(Mix.env()),
      description: "Async consists on a worker pool for asynchronous execution of tasks (i.e. functions).",
      package: package(),
      source_url: "https://github.com/aruki-delivery/async",
      homepage_url: "https://hex.pm/packages/async"]
  end

  defp deps(_) do
    [{:ex_doc, ">= 0.0.0", only: :dev}]
  end

  def package do
    [ maintainers: ["cblage"],
      licenses: ["Apache License 2.0"],
      links: %{"GitHub" => "https://github.com/aruki-delivery/async" } ]
  end
end