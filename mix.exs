defmodule LAP2.MixProject do
  use Mix.Project

  def project do
    [
      app: :lap2,
      version: "0.1.0",
      elixir: "~> 1.13",
      start_permanent: Mix.env() == :prod,
      deps: deps(),

      # Docs
      name: "LAP2",
      source_url: "https://github.com/r1ghtwr0ng/lap2",
      homepage_url: "http://github.com/r1ghtwr0ng/lap2",
      docs: [main: "LAP2",
            logo: "assets/images/logo.png",
            extras: ["README.md"],
            groups_for_modules: group_for_modules(),
            nest_modules_by_prefix: nest_modules_by_prefix()
          ]
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
      {:protox, "~> 1.7"},
      {:elixir_make, "~> 0.6"},
      {:ex_crypto, "~> 0.10.0"},
      {:keyx, "~> 0.4.1"},
      {:rustler, "~> 0.28.0"},
      {:ex_doc, "~> 0.21", only: :dev, runtime: false}
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
    ]
  end

  def run(_argv) do
    Mix.Task.run("compile")
    Mix.Task.run("test")
    Mix.Task.run("run", ["-e", "LAP2.start"])
  end

  # ---- Docs formatting ----
  defp group_for_modules() do
    [
      "Cryptography": [
        LAP2.Crypto.CryptoManager,
        LAP2.Crypto.InformationDispersal.RabinIDA,
        LAP2.Crypto.InformationDispersal.SecureIDA,
        LAP2.Crypto.Padding.PKCS7,
        LAP2.Crypto.Helpers.CryptoStructHelper
        ],
      "Networking": [
        LAP2.Networking.Router,
        LAP2.Networking.Resolver,
        LAP2.Networking.ProtoBuf,
        LAP2.Networking.Sockets.UdpServer,
        LAP2.Networking.Sockets.Lap2Socket,
        LAP2.Networking.Helpers.OutboundPipelines,
        LAP2.Networking.Helpers.RelaySelector,
        LAP2.Networking.Routing.Local,
        LAP2.Networking.Routing.Remote,
        LAP2.Networking.Helpers.State,
      ],
      "Utilities": [
        LAP2.Utils.ConfigParser,
        LAP2.Utils.JsonUtils,
        LAP2.Utils.EtsHelper,
        LAP2.Utils.ProtoBuf.CloveHelper,
        LAP2.Utils.ProtoBuf.ShareHelper,
        LAP2.Utils.ProtoBuf.RequestHelper
      ],
      "Maths": [LAP2.Math.Matrix],
      "Control": [
        LAP2,
        LAP2.Main.Master,
        LAP2.Main.ProxyManager,
        LAP2.Main.StructHandlers.RequestHandler,
        LAP2.Main.StructHandlers.ShareHandler,
        LAP2.Main.Helpers.ProcessorState,
        LAP2.Main.Helpers.ProxyHelper
      ]
    ]
  end

  defp nest_modules_by_prefix() do
    [
      # Utils
      LAP2.Utils,
      LAP2.Utils.ProtoBuf,
      # Networking
      LAP2.Networking,
      LAP2.Networking.Routing,
      LAP2.Networking.Sockets,
      LAP2.Networking.Helpers,
      # Crypto
      LAP2.Crypto,
      Crypto.InformationDispersal,
      LAP2.Crypto.Padding,
      LAP2.Crypto.Helpers,
      # Math
      LAP2.Math,
      # Main
      LAP2.Main,
      LAP2.Main.StructHandlers,
      LAP2.Main.Helpers,
    ]
  end
end
