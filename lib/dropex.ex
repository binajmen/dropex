defmodule Dropex do
  use GenServer

  require Logger

  @table :dropex
  @key :token
  @refresh_threshold 14340

  # Client API

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @spec get_token() ::
          {:ok, access_token :: String.t(), refresh_token :: String.t()}
          | {:refresh, refresh_token :: String.t()}
          | {:error, reason :: String.t()}
  def get_token() do
    GenServer.call(__MODULE__, :get_token)
  end

  def refresh_token(refresh_token) do
    GenServer.call(__MODULE__, {:refresh_token, refresh_token})
  end

  def set_token(access_token, refresh_token, expires_in) do
    GenServer.cast(__MODULE__, {:set_token, access_token, refresh_token, expires_in})
  end

  def rotate_token() do
    GenServer.cast(__MODULE__, :rotate_token)
  end

  # Server callbacks

  @impl true
  def init(_opts) do
    :ets.new(@table, [:set, :protected, :named_table])
    {:ok, %{refresh_timer: nil}}
  end

  @impl true
  def handle_call(:get_token, _from, state) do
    Logger.info("handle_call/:get_token")

    case :ets.lookup(@table, @key) do
      [{:token, access_token, refresh_token, expiration}] ->
        if :os.system_time(:second) < expiration - @refresh_threshold do
          {:reply, {:ok, access_token, refresh_token}, state}
        else
          {:reply, {:refresh, refresh_token}, state}
        end

      [] ->
        {:reply, {:error, "token not found"}, state}
    end
  end

  def handle_call({:refresh_token, refresh_token}, _from, state) do
    refresh_token(refresh_token, state)
  end

  @impl true
  def handle_cast({:set_token, access_token, refresh_token, expires_in}, state) do
    Logger.info("handle_call/:set_token")

    expiration = :os.system_time(:second) + expires_in
    :ets.insert(@table, {@key, access_token, refresh_token, expiration})

    if state.refresh_timer, do: Process.cancel_timer(state.refresh_timer)
    refresh_timer = schedule_refresh(expires_in - @refresh_threshold)

    {:noreply, %{state | refresh_timer: refresh_timer}}
  end

  @impl true
  def handle_info(:rotate_token, state) do
    Logger.info("handle_info/:rotate_token")

    case :ets.lookup(@table, @key) do
      [{:token, _access_token, refresh_token, _expiration}] ->
        refresh_token(refresh_token, state)

      [] ->
        Logger.warning("no token found")
        {:noreply, %{state | refresh_timer: nil}}
    end
  end

  # Helper functions

  defp refresh_token(refresh_token, state) do
    case Dropex.OAuth.refresh_access_token(refresh_token) do
      {:ok, access_token, refresh_token, expires_in} ->
        Dropex.set_token(access_token, refresh_token, expires_in)
        {:noreply, %{state | refresh_timer: nil}}

      {:error, reason} ->
        Logger.error("failed to refresh token: #{inspect(reason)}")
        {:noreply, %{state | refresh_timer: nil}}
    end
  end

  defp schedule_refresh(time) do
    Process.send_after(self(), :rotate_token, time * 1000)
  end
end
