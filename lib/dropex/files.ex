defmodule Dropex.Files do
  import Dropex.Client

  @spec copy(from_path :: String.t(), to_path :: String.t()) :: any()
  def copy(from_path, to_path) do
    new_request(:post, "/files/copy")
    |> set_bearer()
    |> set_json(%{from_path: from_path, to_path: to_path})
    |> run_request()
  end

  @spec create_folder_batch(paths :: nonempty_list(String.t())) :: any()
  def create_folder_batch(paths) do
    new_request(:post, "/files/create_folder_batch")
    |> set_bearer()
    |> set_json(%{paths: paths})
    |> IO.inspect()
    |> run_request()
  end

  @spec download(path :: String.t()) :: any()
  def download(path) do
    headers = [
      {"dropbox-api-arg", Jason.encode!(%{path: path})}
    ]

    new_request(:post, "/files/download", :content)
    |> set_bearer()
    |> set_headers(headers)
    |> run_request()
  end

  @spec list_folder(path :: String.t()) :: any()
  def list_folder(path) do
    new_request(:post, "/files/list_folder")
    |> set_bearer()
    |> set_json(%{path: path})
    |> run_request()
  end

  @spec upload(path :: String.t()) :: any()
  def upload(path) do
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
    |> set_bearer()
    |> set_headers(headers)
    |> set_body(file_contents)
    |> run_request()
  end
end
