defmodule AppCount.Data.Utils.Files do
  def file_type(<<255, 216, 255>> <> _), do: :jpg
  def file_type(<<137, 80, 78, 71, 13, 10, 26, 10>> <> _), do: :png
  def file_type(<<37, 80, 68, 70, 45>> <> _), do: :pdf
  def file_type(<<71, 73, 70, 56, 57, 97>> <> _), do: :gif
  def file_type(<<71, 73, 70, 56, 59, 97>> <> _), do: :gif
  def file_type(<<208, 207, 17, 224, 161, 177, 26, 225>> <> _), do: :doc
  def file_type(<<80, 75, 3, 4>> <> _), do: :zip
  def file_type(<<80, 75, 5, 6>> <> _), do: :zip
  def file_type(<<80, 75, 7, 8>> <> _), do: :zip
  def file_type(<<73, 73, 42, 0>> <> _), do: :tiff
  def file_type(<<77, 77, 0, 42>> <> _), do: :tiff
  def file_type(<<255, 251>> <> _), do: :mp3
  def file_type(<<73, 68, 51>> <> _), do: :mp3
  def file_type(<<82, 73, 70, 70, _, _, _, _, 65, 86, 73, 32>> <> _), do: :avi
  def file_type(<<82, 73, 70, 70, _, _, _, _, 87, 65, 86, 69>> <> _), do: :wav
  def file_type(<<_, _, _, _, 102, 116, 121, 112, 109, 109, 112, 52>> <> _), do: :mp4
  def file_type(<<_, _, _, _, 102, 116, 121, 112, 105, 115, 111, 109>> <> _), do: :mp4
  def file_type(<<_, _, _, _, 102, 116, 121, 112, 105, 115, 111, 50>> <> _), do: :mp4
  def file_type(<<_, _, _, _, 102, 116, 121, 112, 109, 112, 52, 49>> <> _), do: :mp4
  def file_type(<<_, _, _, _, 102, 116, 121, 112, 109, 112, 52, 50>> <> _), do: :mp4
  def file_type(<<_, _, _, _, 102, 116, 121, 112, 97, 118, 99, 49>> <> _), do: :mp4
  def file_type(_), do: :txt

  def verify_file_type(%AppCount.Data.UploadURL{} = upload) do
    case HTTPoison.get(upload.url) do
      {:ok, %{body: body}} -> file_type(body)
    end
  end
end
