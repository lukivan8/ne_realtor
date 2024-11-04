defmodule DiffChecker do
  def diff(prev_list, new_list) do
    prev_map = Map.new(prev_list, &{&1.link, &1})
    new_map = Map.new(new_list, &{&1.link, &1})

    %{
      additions: find_additions(prev_map, new_map),
      deletions: find_deletions(prev_map, new_map),
      price_changes: find_price_changes(prev_map, new_map)
    }
  end

  def is_empty?(diff) do
    Enum.empty?(diff.additions) and Enum.empty?(diff.deletions) and
      Enum.empty?(diff.price_changes.increases) and Enum.empty?(diff.price_changes.decreases)
  end

  defp find_additions(prev_map, new_map) do
    new_map
    |> Map.keys()
    |> Enum.reject(&Map.has_key?(prev_map, &1))
    |> Enum.map(&Map.get(new_map, &1))
  end

  defp find_deletions(prev_map, new_map) do
    prev_map
    |> Map.keys()
    |> Enum.reject(&Map.has_key?(new_map, &1))
    |> Enum.map(&Map.get(prev_map, &1))
  end

  defp find_price_changes(prev_map, new_map) do
    prev_map
    |> Map.keys()
    |> Enum.filter(&Map.has_key?(new_map, &1))
    |> Enum.reduce(%{increases: [], decreases: []}, fn link, acc ->
      prev_apt = Map.get(prev_map, link)
      new_apt = Map.get(new_map, link)

      price_change = %{
        apartment: new_apt,
        previous_price: prev_apt.price,
        new_price: new_apt.price,
        difference: (prev_apt.price - new_apt.price) |> abs()
      }

      cond do
        prev_apt.price > new_apt.price -> Map.update!(acc, :decreases, &[price_change | &1])
        prev_apt.price < new_apt.price -> Map.update!(acc, :increases, &[price_change | &1])
        true -> acc
      end
    end)
  end
end
