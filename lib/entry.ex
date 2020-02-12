defmodule Ledger.Entry do
  @moduledoc false

  defstruct date: nil,
            date_alternative: nil,
            status: nil,
            payee: nil,
            tags: [],
            entries: []

  @line_length 55

  def amount_to_str([cur, amt]) do
    case cur do
      "$" -> "#{cur}#{amt}"
      _ -> "#{cur} #{amt}"
    end
  end

  defp items_to_string(items, indent) do
    items
    |> Enum.map(fn
      [{:account_name, account}, {:amount, amount}, [tag_k, tag_v]] ->
        pre = "#{indent}#{account}"

        padded_amount =
          amount |> amount_to_str |> String.pad_leading(@line_length - String.length(pre))

        "#{pre}#{padded_amount} ; #{tag_k}: #{tag_v}"


      [account_name: account, amount: amount, balance_assertion: balance_assertion] ->
        pre = "#{indent}#{account}"

        amount_with_assert =
          (amount |> amount_to_str) <> " = " <> (balance_assertion |> amount_to_str)

        padded_amount = amount_with_assert |> String.pad_leading(@line_length - String.length(pre))

        "#{pre}#{padded_amount}"

      [account_name: account, amount: amount] ->
        pre = "#{indent}#{account}"

        padded_amount =
          amount |> amount_to_str |> String.pad_leading(@line_length - String.length(pre))

        "#{pre}#{padded_amount}"

      [account_name: account, balance_assertion: balance_assertion] ->
        pre = "#{indent}#{account}"

        padded_assert =
          (" = " <> (balance_assertion |> amount_to_str)) |> String.pad_leading(@line_length - String.length(pre))

        "#{pre}#{padded_assert}"

      [account_name: account] ->
        "#{indent}#{account}"
    end)
    |> Enum.join("\n")
  end

  defp tags_to_string(tags, indent, joiner \\ "\n") do
    tags
    |> Enum.map(fn [k, v] ->
      "#{indent}; #{k}: #{v}"
    end)
    |> Enum.join(joiner)
  end

  def to_string(r) do
    alt_date = if r.date_alternative != nil do
      "#{r.date}=#{r.date_alternative}"
    else
      "#{r.date}"
    end

    status = if r.status != nil do
      "#{r.status}"
    else
      ""
    end

    ([
      [alt_date, status, r.payee]|> Enum.filter(fn x -> x != nil end)|> Enum.filter(fn x -> String.length(x) > 0 end) |> Enum.join(" "),
      "#{tags_to_string(r.tags, "    ")}",
      "#{items_to_string(r.entries, "    ")}"
    ]
    |> Enum.filter(fn x -> String.length(x) != 0 end)) ++ [""]
    |> Enum.join("\n")
  end
end
