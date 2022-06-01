defmodule AppCount.DBScripts do
  alias AppCount.Repo

  @scripts [
    "insert_receipts",
    "charge_trigger",
    "drop_charge_trigger",
    #    "create_charge_trigger",
    "payment_trigger",
    "drop_payment_trigger"
    #    "create_payment_trigger"
  ]

  @sql Enum.into(
         @scripts,
         %{},
         fn script_name ->
           script =
             Path.expand("./#{script_name}.sql", __DIR__)
             |> File.read!()

           {script_name, script}
         end
       )

  def run_script(name) do
    Ecto.Adapters.SQL.query(Repo, @sql[name], [], log: false)
  end

  def run_scripts() do
    @scripts
    |> Enum.each(&Ecto.Adapters.SQL.query(Repo, @sql[&1], [], log: false))
  end
end
