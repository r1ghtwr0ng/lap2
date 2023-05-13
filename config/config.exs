import Config

config :logger, level: :warn

import_config "#{config_env()}.exs"
