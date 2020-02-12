defmodule Ledger.Parsers.Date do
  @moduledoc false
  # credo:disable-for-this-file Credo.Check.Refactor.PipeChainStart
  import NimbleParsec

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

  date_usa =
    integer(min: 1, max: 2)
    |> ignore(date_seperator)
    |> integer(min: 1, max: 2)
    |> ignore(date_seperator)
    |> integer(min: 2, max: 4)
    |> reduce(:date_usa_to_date)

  any_date_format =
    [date_int, date_usa]
    |> choice()
    |> label("date")

  defp date_int_to_date([y, m, d]) do
    {:ok, res} = Date.new(y, m, d)
    res
  end

  defp date_usa_to_date([m, d, y]) do
    {:ok, res} = Date.new(y, m, d)
    res
  end

  defparsec(:date, any_date_format)

  defparsec(:date_int, date_int)

  def parse(x) do
    case date(x) do
      {:ok, [res], _, _, _, _} -> res
      _ -> nil
    end
  end
end
