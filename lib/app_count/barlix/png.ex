defmodule AppCount.Barlix.PNG do
  @moduledoc """
  This module implements the PNG renderer.
  """
  @white 255
  @black 0

  @doc """
  Renders the given code in png image format.

  ## Options

  * `:file` - (path) - target file path.
  * `:xdim` - (integer) - width of a single bar in pixels. Defaults to `1`.
  * `:height` - (integer) - height of the bar in pixels. Defaults to `100`.
  * `:margin` - (integer) - margin size in pixels. Defaults to `10`.
  """
  @spec data(Barlix.code(), Keyword.t()) :: String.t()
  def data({:D1, code}, options) do
    xdim = Keyword.get(options, :xdim, 1)
    height = Keyword.get(options, :height, 100)
    margin = Keyword.get(options, :margin, 10)
    width = xdim * length(code) + margin * 2
    write_png(row(code, xdim, margin), width, height, margin)
  end

  defp row(code, xdim, margin) do
    margin_pixels = map_seq(margin, fn _ -> @white end)
    white = Enum.map(1..xdim, fn _ -> @white end)
    black = Enum.map(1..xdim, fn _ -> @black end)

    bar_pixels =
      Enum.map(
        code,
        fn x ->
          case x do
            1 -> black
            0 -> white
          end
        end
      )

    [margin_pixels, bar_pixels, margin_pixels]
  end

  defp append(png, {:row, row}), do: append(png, {:data, [0, row]})

  defp append(%{z: z} = png, {:data, raw_data}) do
    compressed = :zlib.deflate(z, raw_data)
    append(png, {:compressed, compressed})
  end

  defp append(%{z: _}, {:compressed, []}), do: ""

  defp append(%{z: _}, {:compressed, compressed}) do
    f = fn part, acc -> acc <> :png.chunk("IDAT", part) end
    Enum.reduce(compressed, "", f)
  end

  defp start_data({width, height}) do
    bit_depth = 8
    color_type = 0

    <<
      width::unsigned-32,
      height::unsigned-32,
      bit_depth::unsigned-8,
      color_type::unsigned-8,
      color_type::unsigned-8,
      color_type::unsigned-8,
      color_type::unsigned-8
    >>
  end

  defp write_png(row, width, height, margin) do
    z = :zlib.open()
    :ok = :zlib.deflateInit(z)

    png_options = %{
      size: {width, height + 2 * margin},
      z: z
    }

    start = :png.header() <> :png.chunk("IHDR", start_data(png_options.size))
    margin_row = map_seq(width, fn _ -> @white end)

    margin_data =
      Enum.reduce(1..margin, "", fn _, acc -> acc <> append(png_options, {:row, margin_row}) end)

    barcode_data =
      Enum.reduce(
        1..height,
        "",
        fn _, acc ->
          acc <> append(png_options, {:row, row})
        end
      )

    bottom_margin_data =
      Enum.reduce(1..margin, "", fn _, acc -> acc <> append(png_options, {:row, margin_row}) end)

    closing = :zlib.deflate(z, "", :finish)
    png_close = append(png_options, {:compressed, closing})
    png_end = :png.chunk("IEND", "")
    :zlib.deflateEnd(z)
    :zlib.close(z)
    start <> margin_data <> barcode_data <> bottom_margin_data <> png_close <> png_end
  end

  defp map_seq(size, callback) do
    if size > 0, do: Enum.map(1..size, fn x -> callback.(x) end), else: []
  end
end
