defmodule AppCount.Excel.ExcelTest do
  use AppCount.Case
  @moduletag :excel
  @data File.read!(Path.expand("../../resources/excel/sample.json", __DIR__))
        |> Jason.decode!()

  test "generates workbook" do
    type =
      AppCount.Excel.to_workbook(@data)
      |> AppCount.Data.Utils.Files.file_type()

    assert type == :zip
  end
end
