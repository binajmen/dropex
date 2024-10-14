defmodule Dropex do
  use GenServer

  require Logger

  @table_name :dropex_tokens
  @refresh_threshold 300

  # Client API

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def get_token() do
    GenServer.call(__MODULE__, :get_token)
  end

  def set_token(access_token, refresh_token, expires_in) do
    GenServer.cast(__MODULE__, {:set_token, access_token, refresh_token, expires_in})
  end

  # Server callbacks

  @impl true
  def init(_opts) do
    :ets.new(@table_name, [:set, :protected, :named_table])
    {:ok, %{refresh_timer: nil}}
  end

  @impl true
  def handle_call(:get_token, _from, state) do
    Logger.info("Retrieving Dropbox token from ETS")

    case :ets.lookup(@table_name, :token) do
      [{:token, access_token, _refresh_token, expiration}] ->
        if :os.system_time(:second) < expiration - @refresh_threshold do
          {:reply, {:ok, access_token}, state}
        else
          {:reply, {:error, "Access token is expired"}, state}
        end

      [] ->
        {:reply, {:error, "No token found"}, state}
    end
  end

  @impl true
  def handle_call({:refresh_token, refresh_token}, _from, state) do
    Logger.info("Forcing refresh of token")

    case Dropex.OAuth.refresh_access_token(refresh_token) do
      {:ok, _, _} ->
        Logger.info("Token refreshed")

      {:error, reason} ->
        Logger.error("Failed to refresh token: #{inspect(reason)}")
    end

    {:noreply, %{state | refresh_timer: nil}}
  end

  @impl true
  def handle_cast({:set_token, access_token, refresh_token, expires_in}, state) do
    Logger.info("Inserting Dropbox token in ETS")

    expiration = :os.system_time(:second) + expires_in
    :ets.insert(@table_name, {:token, access_token, refresh_token, expiration})

    # Cancel any existing timer
    if state.refresh_timer, do: Process.cancel_timer(state.refresh_timer)

    # Schedule token refresh
    refresh_timer = schedule_refresh(expires_in - @refresh_threshold)

    {:noreply, %{state | refresh_timer: refresh_timer}}
  end

  @impl true
  def handle_info(:auto_refresh, state) do
    Logger.info("Refreshing Dropbox token")

    case :ets.lookup(@table_name, :token) do
      [{:token, _access_token, refresh_token, _expiration}] ->
        case Dropex.OAuth.refresh_access_token(refresh_token) do
          {:ok, _, _} ->
            Logger.info("Token refreshed")

          {:error, reason} ->
            Logger.error("Failed to refresh token: #{inspect(reason)}")
        end

      [] ->
        Logger.warning("No token found to refresh")
    end

    {:noreply, %{state | refresh_timer: nil}}
  end

  # Helper functions

  defp schedule_refresh(time) do
    Process.send_after(self(), :auto_refresh, time * 1000)
  end
end
