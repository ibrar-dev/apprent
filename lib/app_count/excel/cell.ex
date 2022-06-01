defmodule AppCount.Excel.Cell do
  alias Elixlsx.Sheet
  import AppCount.Excel.Utils

  defstruct data: nil, styles: []

  @styles %{
    "bold" => [
      bold: true
    ],
    "bg_header" => [
      bg_color: "#b2b8c2"
    ],
    "border-top" => [
      border: [
        top: [
          style: :thin,
          color: "#000000"
        ]
      ]
    ],
    "wrap" => [
      wrap_text: true
    ],
    "currency" => [
      num_format: "#,##0.00"
    ],
    "align-right" => [
      align_horizontal: :right
    ]
  }

  def build_table_cell({cell, column}, {sheet, max_row}, starting_index) when is_list(cell) do
    cell
    |> Enum.with_index()
    |> Enum.reduce(
      {sheet, max_row},
      fn {el, index}, {a, current_max} ->
        row_number = starting_index + index
        new_max_row = Enum.max([current_max, row_number])
        build_table_cell({el, column}, {a, new_max_row}, row_number)
      end
    )
  end

  def build_table_cell({%{} = cell_data, column}, {a, max_row}, row_number) do
    %{data: data, styles: style} = to_struct(__MODULE__, cell_data)
    styles = Enum.reduce(style, [], fn code, s -> Keyword.merge(s, @styles[code]) end)
    {Sheet.set_cell(a, <<column + 65>> <> "#{row_number}", data, styles), max_row}
  end

  def build_table_cell({cell, column}, {a, max_row}, row_number) do
    {Sheet.set_cell(a, <<column + 65>> <> "#{row_number}", cell), max_row}
  end

  def convert_table_row(row_data) do
    Enum.map(
      row_data,
      fn
        %{data: data, styles: styles} ->
          [data] ++ Enum.reduce(styles, [], &Keyword.merge(&2, @styles[&1]))

        data ->
          [data]
      end
    )
  end
end
