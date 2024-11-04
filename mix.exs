defmodule NeRealtor.MixProject do
  use Mix.Project

  def project do
    [
      app: :ne_realtor,
      version: "0.1.0",
      elixir: "~> 1.17",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {NeRealtor.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:req, "~> 0.5.0"},
      {:floki, "~> 0.36.0"},
      {:telegram, github: "visciang/telegram", tag: "2.0.0"},
      {:hackney, "~> 1.19.0"},
      {:timex, "~> 3.7"},
      {:httpoison, "~> 2.2"}
    ]
  end
end
