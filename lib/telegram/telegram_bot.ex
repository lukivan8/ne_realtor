defmodule TelegramBot do
  use Telegram.Bot
  def token, do: System.get_env("TELEGRAM_BOT_TOKEN")

  @impl true
  def handle_update(
        %{
          "message" => %{
            "text" => "/start" <> _,
            "chat" => %{"id" => chat_id},
            "message_id" => message_id
          }
        },
        token
      ) do
    start_message_text = """
    Добро пожаловать\\. Я Не Риэлтор и я помогу вам отслеживать интересующие вас предложения на krisha\\.kz

    Инструкция для начала работы:
    1\\. Перейдите на krisha\\.kz и скопируйте ссылку на поиск с интересующими вас фильтрами
    2\\. Напишите команду `/follow <ССЫЛКА ПОИСКА>`

    Теперь каждые полчаса если что\\-либо по вашему поиску обновилось, мы отправим вам сообщение\\. Если изменений нет, то лишних сообщений не будет

    Остальные команды:
    \\- `/status` для получения времени последнего обновления и последней проверки
    \\- `/stop` прекращает отслеживание поиска
    \\- `/update <ССЫЛКА ПОИСКА>` для изменения параметров поиска
    """

    Telegram.Api.request(token, "sendMessage",
      chat_id: chat_id,
      reply_to_message_id: message_id,
      parse_mode: "MarkdownV2",
      text: start_message_text
    )
    |> log_response_error()
  end

  @impl true
  def handle_update(
        %{
          "message" => %{
            "text" => "/follow " <> link,
            "chat" => %{"id" => chat_id},
            "message_id" => message_id
          }
        },
        token
      ) do
    {:ok, data} = NeRealtor.Service.spin_up_new_scheduler(link, chat_id |> to_string())

    text = """
    Запущено отслеживание поиска!
    Изначальные предложения #{length(data)} шт.
    """

    Telegram.Api.request(token, "sendMessage",
      chat_id: chat_id,
      text: text,
      reply_to_message_id: message_id
    )
  end

  def handle_update(update, token) do
    Telegram.Command.unknown(token, update)
  end

  def send_update(chat_id, diffs) do
    text = "Diffs: #{inspect(diffs, pretty: true)}"

    Telegram.Api.request(token(), "sendMessage", chat_id: chat_id, text: text)
  end

  def log_response_error({:error, error}) do
    Logger.error("Error when sending message: #{inspect(error)}")
    nil
  end

  def log_response_error(_), do: nil
end
