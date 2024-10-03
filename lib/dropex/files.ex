defmodule Dropex.Files do
  import Dropex.Client

  def list_folder(path) do
    new_request(:post, "/files/list_folder")
    |> set_bearer()
    |> set_json(%{path: path})
    |> run_request()
  end

  def upload(access_token, path) do
    filename = Path.basename(path)
    {:ok, file_contents} = File.read(path)

    headers = [
      {"content-type", "application/octet-stream"},
      {"content-length", "#{byte_size(file_contents)}"},
      {"dropbox-api-arg",
       Jason.encode!(%{
         autorename: false,
         mode: "add",
         mute: false,
         path: "/" <> filename,
         strict_conflict: false
       })}
    ]

    new_request(:post, "/files/upload", :content)
    |> set_bearer(access_token)
    |> set_headers(headers)
    |> set_body(file_contents)
    |> run_request()
  end

  def download(access_token, path) do
    headers = [
      {"dropbox-api-arg", Jason.encode!(%{path: path})}
    ]

    new_request(:post, "/files/download", :content)
    |> set_bearer(access_token)
    |> set_headers(headers)
    |> run_request()
  end
end
