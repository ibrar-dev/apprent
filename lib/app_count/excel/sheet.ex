defmodule AppCount.Excel.Sheet do
  require Elixlsx
  alias Elixlsx.Sheet
  import AppCount.Excel.{Cell, Utils}

  defstruct name: nil,
            heading_color: "#000000",
            heading_bg_color: "#b2b8c2",
            heading_column: "G",
            sheet_headers: [],
            table_head: [],
            table_footer: [],
            data: [],
            widths: []

  def to_sheet(data, opts \\ [])

  def to_sheet(%__MODULE__{} = data, opts) do
    {%Sheet{name: data.name, show_grid_lines: false}, 1}
    |> set_column_widths(data.widths)
    |> build_sheet_headers(data)
    |> build_table_head(data)
    |> build_table_data(data, opts)
    |> build_table_footer(data)
  end

  def to_sheet(data, opts) do
    to_struct(__MODULE__, data)
    |> to_sheet(opts)
  end

  defp set_column_widths({sheet, row}, column_widths) do
    new_sheet =
      column_widths
      |> Enum.with_index()
      |> Enum.reduce(
        sheet,
        fn {width, index}, s ->
          Sheet.set_col_width(s, <<index + 65>>, width)
        end
      )

    {new_sheet, row}
  end

  defp build_table_data(sheet_data, %__MODULE__{data: data}, opts) do
    if opts[:fast] do
      {sheet, row_number} = sheet_data
      rows = Enum.map(data, &convert_table_row/1)
      {update_in(sheet.rows, &(&1 ++ rows)), row_number + length(rows)}
    else
      Enum.reduce(data, sheet_data, &build_table_row/2)
    end
  end

  defp build_table_row(row_data, {sheet, row_number}) do
    row_data
    |> Enum.with_index()
    |> Enum.reduce(
      {sheet, row_number},
      fn row, sheet_tuple ->
        build_table_cell(row, sheet_tuple, row_number)
      end
    )
    |> increment_row
  end

  defp build_table_footer({sheet, row_index}, %__MODULE__{
         table_footer: footer_cells,
         heading_bg_color: bg_color
       }) do
    footer_cells
    |> Enum.with_index()
    |> Enum.reduce(
      sheet,
      fn {cell, index}, a ->
        Sheet.set_cell(
          a,
          <<index + 65>> <> "#{row_index}",
          cell,
          bg_color: bg_color,
          bold: true,
          num_format: "#,##0.00",
          border: [
            top: [
              style: :medium,
              color: "#000000"
            ]
          ]
        )
      end
    )
  end

  defp build_table_head({sheet, row_index}, %__MODULE__{
         table_head: headings,
         heading_bg_color: bg_color
       }) do
    new_sheet =
      headings
      |> Enum.with_index()
      |> Enum.reduce(
        sheet,
        fn {heading, index}, a ->
          Sheet.set_cell(
            a,
            <<index + 65>> <> "#{row_index + 1}",
            heading,
            bg_color: bg_color,
            bold: true,
            border: [
              bottom: [
                style: :medium,
                color: "#000000"
              ]
            ]
          )
        end
      )
      |> Sheet.set_pane_freeze(row_index + 1, 0)

    {new_sheet, row_index + 2}
  end

  defp build_sheet_headers({sheet, row_index}, %__MODULE__{
         sheet_headers: headers,
         heading_column: col
       }) do
    headers
    |> Enum.reduce(
      {sheet, row_index},
      fn header, {a, index} ->
        {Sheet.set_cell(a, "#{col}#{index}", header), index + 1}
      end
    )
  end

  defp increment_row({sheet, row_number}), do: {sheet, row_number + 1}
end
