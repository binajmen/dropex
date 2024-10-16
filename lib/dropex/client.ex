defmodule Dropex.Client do
  @moduledoc """
  HTTP client for interacting with the Dropbox API.
  """

  @rpc_endpoint "https://api.dropboxapi.com/2"
  @content_endpoint "https://content.dropboxapi.com/2"
  @oauth_endpoint "https://api.dropboxapi.com"

  def new_request(method, path) do
    Req.new(method: method, url: @rpc_endpoint <> path)
  end

  def new_request(method, path, :content) do
    Req.new(method: method, url: @content_endpoint <> path)
  end

  def new_request(method, path, :oauth) do
    Req.new(method: method, url: @oauth_endpoint <> path)
  end

  def set_bearer(request) do
    case Dropex.get_token() do
      {:ok, access_token, _refresh_token} ->
        Req.merge(request, auth: {:bearer, access_token})

      {:refresh, refresh_token} ->
        Dropex.refresh_token(refresh_token)
        set_bearer(request)

      {:error, _reason} ->
        request
    end
  end

  def set_bearer(request, token) do
    Req.merge(request, auth: {:bearer, token})
  end

  def set_headers(request, headers) do
    Req.merge(request, headers: headers)
  end

  def set_hearers_args(request, args) do
    Req.merge(request, headers: %{"dropbox-api-arg" => Jason.encode!(args)})
  end

  def set_root_namespace_id(request) do
    case Application.fetch_env(:dropex, :root_namespace_id) do
      {:ok, root_namespace_id} ->
        Req.merge(request,
          headers: %{
            "dropbox-api-path-root":
              Jason.encode!(%{".tag" => "root", "root" => root_namespace_id})
          }
        )

      :error ->
        request
    end
  end

  def set_body(request, body) do
    Req.merge(request, body: body)
  end

  def set_form(request, payload) do
    Req.merge(request, form: payload)
  end

  def set_json(request, payload) do
    Req.merge(request, json: payload)
  end

  def run_request(request, retries \\ 0) do
    res =
      set_root_namespace_id(request)
      |> Req.request()

    case res do
      {:ok, %Req.Response{status: 200} = res} ->
        res.body

      {:ok, %Req.Response{status: 400, body: %{"error" => %{".tag" => "expired_access_token"}}}} ->
        case retries < 2 do
          true ->
            with {:ok, access_token, _refresh_token} = Dropex.get_token() do
              request
              |> set_bearer(access_token)
              |> run_request(retries + 1)
            end

          false ->
            {:error, "Unable to refresh expired accesss token"}
        end

      {:ok, %Req.Response{status: 400, body: %{"error" => %{".tag" => "invalid_access_token"}}}} ->
        res.body

      {:error, exception} ->
        raise exception
    end
  end
end
