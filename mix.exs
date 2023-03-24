defmodule LAP2.MixProject do
  use Mix.Project

  def project do
    [
        app: :lap2,
        version: "0.1.0",
        elixir: "~> 1.13",
        start_permanent: Mix.env() == :prod,
        deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
        {:jason, "~> 1.4"},
        {:crc, "~> 0.10.4"},
        {:protox, "~> 1.7"}
        # {:dep_from_hexpm, "~> 0.3.0"},
        # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
    ]
  end

  def run(_argv) do
    Mix.Task.run("compile")
    Mix.Task.run("test")
    Mix.Task.run("run", ["-e", "LAP2.start"])
  end
end
