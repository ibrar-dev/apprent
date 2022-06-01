defmodule AppCount.Data.UploadURL do
  use Ecto.Schema

  @derive {Jason.Encoder,
           only: [
             :url
           ]}

  defmodule URL do
    use Ecto.Type
    @bucket "appcount-uploads"
    def type, do: :text

    def cast(x), do: {:ok, x}

    def load("1:" <> path), do: {:ok, "/images/error.svg?path=#{path}"}
    def load("2:" <> path), do: {:ok, "/images/loading.svg?path=#{path}"}

    def load("3:" <> path),
      do: {:ok, "https://s3-us-east-2.amazonaws.com/#{@bucket}/#{path}"}

    def load("0:" <> path), do: presigned_url(path)

    if Mix.env() == :test do
      def presigned_url(path), do: {:ok, path}
    else
      def presigned_url(path),
        do: ExAws.S3.presigned_url(ExAws.Config.new(:s3), :get, @bucket, path)
    end

    def dump(x) do
      {:ok, x}
    end

    # Several images or documents were uploaded with spaces in the name, this ensures that it wont be a broken link. -OLD
    # This breaks when opening an attachment with a space in it, but does not break when in an img tag.
    # Removing this for now and front end will need to ensure that all links in img tags are proper URI -DA 4/14/21
    # defp encode_path(path) when is_binary(path), do: URI.encode(path)
    # defp encode_path(path), do: path
  end

  schema "data__upload_urls" do
    field :url, URL
  end
end
