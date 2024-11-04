defmodule NeRealtor.Service do
  @moduledoc """
  Client service abstracted from scheduler and telegram bot
  """
  alias NeRealtor.SchedulerSupervisor

  def spin_up_new_scheduler(link, user_id) do
    {:ok, _new_scheduler} = SchedulerSupervisor.start_realtor(link, user_id)
    {:ok, data} = Scheduler.get_data(user_id)
    {:ok, data.data}
  end

  def get_status(user_id) do
    {:ok, data} = Scheduler.get_data(user_id)

    %{
      amount: length(data.data),
      last_updated: data.last_updated,
      last_checked: data.last_checked,
      data: data.data
    }
  end

  def stop(user_id) do
    Scheduler.stop(user_id)
  end

  def update(user_id, new_link) do
    :ok = Scheduler.stop(user_id)
    {:ok, _} = SchedulerSupervisor.start_realtor(new_link, user_id)
    {:ok, data} = Scheduler.get_data(user_id)
    data
  end
end
