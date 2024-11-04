defmodule Telegram.Command do
  require Logger

  def unknown(token, update) do
    unknown_message = "Unknown message:\n\n```\n#{inspect(update, pretty: true)}\n```"

    case update do
      %{"message" => %{"message_id" => message_id, "chat" => %{"id" => chat_id}}} ->
        Telegram.Api.request(token, "sendMessage",
          chat_id: chat_id,
          reply_to_message_id: message_id,
          parse_mode: "MarkdownV2",
          text: unknown_message
        )

      _ ->
        Logger.debug(unknown_message)
    end
  end
end
