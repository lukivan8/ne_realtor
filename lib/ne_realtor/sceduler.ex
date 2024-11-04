defmodule Scheduler do
  use Timex
  use GenServer
  require Logger

  @moduledoc """
  Main module for NeRealtor and the GenServer.

  GenServer is spinned up for every user. And updates the state every hour logging differences from DiffChecker.

  Example state:
  ```
  %{
    data: [%Apartment{...}, %Apartment{...}],
    url: "https://krisha.kz/arenda/kvartiry/karaganda/?das%5Blive.rooms%5D=1",
    user_id: "123456789",
    last_checked: ~N[2024-10-30 12:00:00],
    last_updated: ~N[2024-10-30 9:00:00],
  }
  ```
  """

  @interval 30 * 1000

  def start_link(url, user_id) when is_binary(url) and is_binary(user_id) do
    name = via_tuple(user_id)
    now = Timex.now() |> Timex.to_naive_datetime()
    Logger.info("Starting NeRealtor for user #{user_id}")

    GenServer.start_link(
      __MODULE__,
      %{url: url, user_id: user_id, data: [], last_updated: now, last_checked: now},
      name: name
    )
  end

  def get_data(user_id) do
    case lookup(user_id) do
      {:ok, pid} -> {:ok, GenServer.call(pid, :get_data)}
      {:error, _} = error -> error
    end
  end

  def stop(user_id) do
    case lookup(user_id) do
      {:ok, pid} ->
        GenServer.stop(pid)
        DynamicSupervisor.terminate_child(NeRealtor.Supervisor, pid)

      {:error, _} = error ->
        error
    end
  end

  def lookup(user_id) do
    case Registry.lookup(NeRealtor.Registry, user_id) do
      [{pid, _}] -> {:ok, pid}
      [] -> {:error, :not_found}
    end
  end

  @impl true
  def init(state \\ %{data: [], url: nil, user_id: nil}) do
    immediate_parse(state) |> continue()
  end

  @impl true
  def handle_continue(:start_scheduling, state) do
    Process.send_after(self(), :update, @interval)
    {:noreply, state}
  end

  @impl true
  def handle_info(:update, state) do
    {:ok, new_state} = update(state)
    {:noreply, new_state, {:continue, :start_scheduling}}
  end

  @impl true
  def handle_call(:get_data, _from, state) do
    user_data = %{
      data: state.data,
      last_checked: state.last_checked |> Timex.from_now(),
      last_updated: state.last_updated |> Timex.from_now()
    }

    {:reply, user_data, state}
  end

  def update(state) do
    Logger.info("Updating data for user #{state.user_id}")
    new_data = Parser.parse(state.url)
    diffs = DiffChecker.diff(state.data, new_data)
    now = Timex.now() |> Timex.to_naive_datetime()

    if DiffChecker.is_empty?(diffs) do
      Logger.info("No diffs for #{state.user_id}")
      {:ok, %{state | last_checked: now}}
    else
      Logger.info("Diffs for #{state.user_id}: \n#{inspect(diffs)}")
      TelegramBot.send_update(state.user_id, diffs)
      {:ok, %{state | data: new_data, last_updated: now, last_checked: now}}
    end
  end

  defp via_tuple(user_id) do
    {:via, Registry, {NeRealtor.Registry, user_id}}
  end

  defp immediate_parse(state) do
    Parser.parse(state.url)
    |> case do
      [_ | _] = initial_data ->
        Logger.info(
          "Initial parse finished for user #{state.user_id}, found #{length(initial_data)} items"
        )

        {:ok, %{state | data: initial_data}}

      _ ->
        Logger.info("Initial parse failed for user #{state.user_id}")
        {:error, :initial_parse_failed}
    end
  end

  defp continue({:ok, new_state}), do: {:ok, new_state, {:continue, :start_scheduling}}
  defp continue({:error, reason}), do: {:stop, reason}
end
