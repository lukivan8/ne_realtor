defmodule NeRealtor.Application do
  use Application

  def start(_type, _args) do
    children = [
      {Registry, keys: :unique, name: NeRealtor.Registry},
      NeRealtor.SchedulerSupervisor,
      {Telegram.Poller,
       bots: [{TelegramBot, token: TelegramBot.token(), max_bot_concurrency: 1_000}]}
    ]

    opts = [strategy: :one_for_one, name: NeRealtor.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
