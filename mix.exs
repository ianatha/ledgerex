defmodule Ledger.MixProject do
  use Mix.Project

  def project do
    [
      app: :ledgerex,
      version: "0.1.0",
      elixir: "~> 1.9",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  defp deps do
    [
      {:nimble_parsec, "~> 0.5"},

      {:credo, "~> 1.1.0", only: [:dev, :test], runtime: false}
    ]
  end
end
