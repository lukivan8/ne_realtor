defmodule NeRealtor.SchedulerSupervisor do
  use DynamicSupervisor

  def start_link(init_arg) do
    DynamicSupervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def start_realtor(url, user_id) do
    child_spec = %{
      id: Scheduler,
      start: {Scheduler, :start_link, [url, user_id]},
      restart: :transient
    }

    DynamicSupervisor.start_child(__MODULE__, child_spec)
  end
end
