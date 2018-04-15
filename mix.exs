defmodule Async.Mixfile do
  use Mix.Project

  def project do
    [app: :async,
      version: "2.0.0",
      deps: deps(Mix.env()),
      language: :erlang,
      description: "Async consists on a worker pool for asynchronous execution of tasks (i.e. functions).",
      package: package(),
      source_url: "https://github.com/aruki-delivery/async",
      homepage_url: "https://hex.pm/packages/async",
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [coveralls: :test],
    ]
  end

  defp deps(_) do
    [
      {:dialyxir, "~> 0.5", only: [:dev], runtime: false},
      {:distillery, "~> 1.5", runtime: false},
      {:mix_test_watch, "~> 0.3", only: :dev, runtime: false},
      {:excoveralls, "~> 0.8", only: :test},
      {:ex_doc, ">= 0.0.0", only: :dev}
    ]
  end


  def application do
    [mod: {:async, []},
      extra_applications: [:logger,],]
  end


  def package do
    [ maintainers: ["cblage"],
      licenses: ["Apache License 2.0"],
      links: %{"GitHub" => "https://github.com/aruki-delivery/async" } ]
  end
end