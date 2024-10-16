import Config

config :dropex,
  client_id: System.get_env("DROPBOX_CLIENT_ID"),
  client_secret: System.get_env("DROPBOX_CLIENT_SECRET"),
  redirect_uri: System.get_env("DROPBOX_REDIRECT_URI"),
  root_namespace_id: "2516218979"
