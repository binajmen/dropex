defmodule Dropex.OAuth do
  import Dropex.Client

  def build_authorization_url() do
    """
    https://www.dropbox.com/oauth2/authorize\
    ?client_id=#{client_id!()}\
    &redirect_uri=#{redirect_uri!()}\
    &response_type=code\
    &token_access_type=offline\
    """
  end

  def get_access_token(code) do
    resp =
      new_request(:post, "/oauth2/token", :oauth)
      |> set_form(%{
        code: code,
        grant_type: "authorization_code",
        redirect_uri: redirect_uri!(),
        client_id: client_id!(),
        client_secret: client_secret!()
      })
      |> run_request()

    case resp do
      %{
        "access_token" => access_token,
        "refresh_token" => refresh_token,
        "expires_in" => expires_in
      } ->
        Dropex.set_token(access_token, refresh_token, expires_in)
        {:ok, access_token}

      _ ->
        {:error, "Failed to obtain access token"}
    end
  end

  def refresh_access_token(refresh_token) do
    resp =
      new_request(:post, "/oauth2/token", :oauth)
      |> set_form(%{
        refresh_token: refresh_token,
        grant_type: "refresh_token",
        client_id: client_id!(),
        client_secret: client_secret!()
      })
      |> run_request()

    case resp do
      %{
        "access_token" => access_token,
        "expires_in" => expires_in
      } ->
        Dropex.set_token(access_token, refresh_token, expires_in)
        {:ok, access_token, expires_in}

      _ ->
        {:error, "Failed to refresh access token"}
    end
  end

  defp client_id!() do
    System.get_env("DROPBOX_CLIENT_ID")
  end

  defp client_secret!() do
    System.get_env("DROPBOX_CLIENT_SECRET")
  end

  defp redirect_uri!() do
    System.get_env("DROPBOX_REDIRECT_URI")
  end
end
