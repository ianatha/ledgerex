defmodule Ledger.Parsers.Ledger do
  @moduledoc false
  # credo:disable-for-this-file Credo.Check.Refactor.PipeChainStart
  import NimbleParsec

  account_name =
    times(
      lookahead_not(string("  "))
      |> ascii_char([?A..?Z, ?a..?z, ?&, ?:, ?0..?9, ?\ ]),
      min: 1
    )
    |> optional(ignore(string("  ")))
    |> wrap()
    |> reduce({List, :to_string, []})

  payee_desc =
    ascii_string(
      [?A..?Z, ?a..?z, ?0..?9, ?\ , ?', ?:, ?., ?-, ?/, ?,, ?&, ?#, ?(, ?), ?*, ?@, ?_],
      min: 1
    )

  whitespace = ignore(times(ascii_char([?\ , ?\t]), min: 1))
  tag_name = ascii_string([{:not, ?:}], min: 1)
  tag_value = ascii_string([{:not, ?\n}], min: 1)

  eol = ignore(string("\n"))

  date_seperator =
    [string("/"), string("-"), string(".")]
    |> choice()

  date_int =
    integer(4)
    |> ignore(date_seperator)
    |> integer(min: 1, max: 2)
    |> ignore(date_seperator)
    |> integer(min: 1, max: 2)
    |> reduce(:date_int_to_date)

  defp date_int_to_date([y, m, d]) do
    {:ok, res} = Date.new(y, m, d)
    res
  end

  transaction_date =
    empty()
    |> concat(date_int)
    |> unwrap_and_tag(:date)

  transaction_date_alternative =
    optional(
      ignore(string("="))
      |> concat(date_int)
      |> unwrap_and_tag(:date_alternative)
    )

  transaction_status =
    optional(
      whitespace
      |> concat(choice([string("!"), string("*")]))
      |> unwrap_and_tag(:status)
    )

  defp tags_to_map(_rest, args, context, _line, _offset) do
    {
      args,
      # |> Enum.map(&List.to_tuple/1)
      # |> Enum.into(%{}),
      context
    }
  end

  tag =
    whitespace
    |> concat(ignore(string("; ")))
    |> concat(tag_name)
    |> concat(ignore(string(": ")))
    |> concat(tag_value)
    |> concat(eol)
    |> wrap()

  tags =
    tag
    |> times(min: 1)
    |> post_traverse({:tags_to_map, []})
    |> tag(:tags)

  currency_amount =
    choice([string("BTC"), string("$")])
    |> optional(whitespace)
    |> concat(ascii_string([?0..?9, ?., ?-, ?,], min: 1))
    |> label("currency_amount")

  account_entry =
    whitespace
    |> concat(
      account_name
      |> unwrap_and_tag(:account_name)
    )
    |> concat(
      optional(
        whitespace
        |> concat(currency_amount)
        |> tag(:amount)
      )
    )
    |> concat(
      optional(
        whitespace
        |> ignore(string("="))
        |> concat(whitespace)
        |> concat(currency_amount)
        |> tag(:balance_assertion)
      )
    )
    # |> optional(whitespace)
    |> concat(choice([tag, whitespace |> concat(eol), eol]))
    |> wrap
    |> label("account_entry")

  account_entries =
    account_entry
    |> times(min: 2)
    |> tag(:entries)
    |> label("account_entries")

  defp entry_to_ledger(entry) do
    Kernel.struct!(%Ledger.Entry{}, entry)
  end

  defp join_and_wrap(_rest, args, context, _line, _offset) do
    {args |> Enum.map(&entry_to_ledger/1), context}
  end

  plain_xact =
    transaction_date
    |> concat(transaction_date_alternative)
    |> concat(transaction_status)
    |> concat(
      optional(
        whitespace
        |> concat(payee_desc)
        |> unwrap_and_tag(:payee)
      )
    )
    |> concat(eol)
    |> concat(optional(tags))
    |> concat(optional(account_entries))
    |> wrap()
    |> post_traverse({:join_and_wrap, []})

  ledger_file =
    plain_xact
    |> repeat(eol)
    |> times(min: 1)
    |> concat(eos())

  defparsec(:xact, ledger_file)

  def parse(x) do
    case xact(x) do
      {:ok, acc, _rest, _context, _line, _column} -> acc
      x -> x
    end
  end
end
