defmodule Parser do
  def parse(url) do
    parse_recursive(url, 1, [])
  end

  defp parse_recursive(url, page, acc) do
    append_page(url, page)
    |> get_html()
    |> parse_apartments()
    |> case do
      [] -> acc
      cards when length(cards) < 10 -> acc ++ cards
      cards -> parse_recursive(url, page + 1, acc ++ cards)
    end
  end

  def get_html(url) do
    %{body: body} = Req.get!(url)
    body
  end

  def parse_apartments(html) do
    html
    |> Floki.parse_document!()
    |> Floki.find("div.a-card")
    |> Enum.map(&parse_apartment/1)
  end

  def parse_apartment(card) do
    link = get_link(card)
    title = get_title(card)
    address = get_address(card)
    price = get_price(card)
    %Apartment{link: link, title: title, address: address, price: price}
  end

  def get_link(card) do
    card
    |> Floki.find("a.a-card__title")
    |> Floki.attribute("href")
    |> List.first()
    |> add_host()
  end

  defp add_host(url), do: "https://krisha.kz" <> url

  def get_title(card) do
    card
    |> Floki.find("a.a-card__title")
    |> Floki.text()
  end

  def get_address(card) do
    card
    |> Floki.find("div.a-card__subtitle")
    |> Floki.text()
    |> String.replace("  ", "")
    |> String.replace("\n", "")
  end

  def get_price(card) do
    card
    |> Floki.find("div.a-card__price")
    |> Floki.text()
    |> String.replace(~r/[^\d]/, "")
    |> String.to_integer()
  end

  defp append_page(url, page), do: append_page(url, page, String.contains?(url, "page="))
  defp append_page(url, page, true = _page), do: String.replace(url, ~r/page=\d+/, "page=#{page}")
  defp append_page(url, page, false = _page), do: url <> "&page=#{page}"
end
