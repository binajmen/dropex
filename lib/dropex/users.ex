defmodule Dropex.Users do
  import Dropex.Client

  def get_current_account() do
    new_request(:post, "/users/get_current_account")
    |> set_bearer()
    |> run_request()
  end
end
