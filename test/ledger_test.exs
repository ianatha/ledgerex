defmodule LedgerTest do
  use ExUnit.Case
  doctest Ledger

  test "simple transaction" do
    assert Ledger.Parsers.Ledger.parse("2019/02/26
  Liabitilies:AMEX
  Transfer:AMEX			$-1,950.00
") == [
             %Ledger.Entry{
               date_alternative: nil,
               payee: nil,
               status: nil,
               tags: [],
               date: ~D[2019-02-26],
               entries: [
                 [account_name: "Liabitilies:AMEX"],
                 [account_name: "Transfer:AMEX", amount: ["$", "-1,950.00"]]
               ]
             }
           ]
  end

  test "simple transaction with balance assertion" do
    assert Ledger.Parsers.Ledger.parse("2019/01/02 Hello
  Liabilities:AMEX       $2000.00
  Income                 $-2000.00 = $0
") == [
             %Ledger.Entry{
               date: ~D[2019-01-02],
               date_alternative: nil,
               entries: [
                 [account_name: "Liabilities:AMEX", amount: ["$", "2000.00"]],
                 [
                   account_name: "Income",
                   amount: ["$", "-2000.00"],
                   balance_assertion: ["$", "0"]
                 ]
               ],
               payee: "Hello",
               status: nil,
               tags: []
             }
           ]
  end
  test "accounts with whitespace" do
    assert Ledger.Parsers.Ledger.parse("2019/01/02 Hello
  ; k1: v1 and whitepsace
  ; k2: v2
  Liabilities:AMEX Or Something       $2000.00
  Income:1\t      $-1000.00
  Income:2\t      $-1000.00
") == [
             %Ledger.Entry{
               date: ~D[2019-01-02],
               date_alternative: nil,
               entries: [
                 [account_name: "Liabilities:AMEX Or Something", amount: ["$", "2000.00"]],
                 [account_name: "Income:1", amount: ["$", "-1000.00"]],
                 [account_name: "Income:2", amount: ["$", "-1000.00"]]
               ],
               payee: "Hello",
               status: nil,
               tags: [["k1", "v1 and whitepsace"], ["k2", "v2"]]
             }
           ]
  end

  test "real entry" do
    assert Ledger.Parsers.Ledger.parse("2019/02/03=2019/02/01 * GOOGLE *GSUITE_TEST.COM
           ; trans_id: 20190203 705357 532 201,902,034,507
           ; trans_type: Debit
           ; ref_num: 564650848
           ; trans_cat: Entertainment
           ; type: Credit Card
           ; balance: $10,336.72
           ; sig: o67cDEwo7q0NTETkkjt7Ow==
           ; imported: 2019-11-10 03:33:31.870056Z
           ; star_prefix: GOOGLE
           Liabilities:MC                  $-5.32
           Expenses:Consulting:GSuite
") == [
             %Ledger.Entry{
               date: ~D[2019-02-03],
               date_alternative: ~D[2019-02-01],
               entries: [
                 [account_name: "Liabilities:MC", amount: ["$", "-5.32"]],
                 [account_name: "Expenses:Consulting:GSuite"]
               ],
               payee: "GOOGLE *GSUITE_TEST.COM",
               status: "*",
               tags: [
                 ["trans_id", "20190203 705357 532 201,902,034,507"],
                 ["trans_type", "Debit"],
                 ["ref_num", "564650848"],
                 ["trans_cat", "Entertainment"],
                 ["type", "Credit Card"],
                 ["balance", "$10,336.72"],
                 ["sig", "o67cDEwo7q0NTETkkjt7Ow=="],
                 ["imported", "2019-11-10 03:33:31.870056Z"],
                 ["star_prefix", "GOOGLE"]
               ]
             }
           ]
  end
end
