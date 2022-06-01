defmodule AppCount.Excel do
  require Elixlsx
  alias Elixlsx.Workbook
  alias AppCount.Excel.Sheet
  @default_options [filename: "generic.xlsx"]

  def to_workbook(data, opts \\ @default_options) do
    %Workbook{sheets: Enum.map(data, &Sheet.to_sheet(&1, opts))}
    |> Elixlsx.write_to_memory(opts[:filename])
    |> case do
      {:ok, {_, binary}} -> binary
      e -> e
    end
  end
end
