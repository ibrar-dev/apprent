defmodule AppCount.EctoTypes.Upload do
  def cast_uploads(cs, fields) do
    Enum.reduce(
      fields,
      cs,
      fn field, cs ->
        case cs.params[field] || cs.params["#{field}"] do
          %Plug.Upload{} = upload -> Ecto.Changeset.put_change(cs, field, upload)
          _ -> cs
        end
      end
    )
  end

  defmacro upload_type(path, resource_name, opts \\ []) do
    [bucket, path] = String.split(path, ":")

    options =
      if opts[:public] do
        [acl: :public_read]
      else
        []
      end

    contents =
      quote do
        use Ecto.Type
        @bucket unquote(bucket)
        @path unquote(path)
        @options unquote(options)

        def type, do: :string

        def cast(filename), do: {:ok, filename}

        def load(fname) do
          env = AppCount.Config.env()
          full_path = "#{@path}/#{env}/#{fname}"

          if @options[:acl] == :public_read do
            {:ok, "https://s3-us-east-2.amazonaws.com/#{@bucket}/#{full_path}"}
          else
            presigned_url(full_path)
          end
        end

        def dump(%Plug.Upload{filename: filename, path: file_path, content_type: type}) do
          {:ok, data} = File.read(file_path)
          {:ok, push_to_aws(filename, data, type)}
        end

        def dump(%{base64: data, filename: filename, content_type: type}) do
          case Base.decode64(data) do
            {:ok, bin} -> {:ok, push_to_aws(filename, bin, type)}
            :error -> :error
          end
        end

        def dump(%{"base64" => data, "filename" => filename, "content_type" => type}) do
          dump(%{base64: data, filename: filename, content_type: type})
        end

        def dump("https://s3" <> rest) do
          url =
            String.split(rest, "/")
            |> Enum.slice(-2..-1)
            |> Enum.join("/")

          {:ok, url}
        end

        def dump(_) do
          :error
        end

        def upload_opts(type) do
          Keyword.merge(@options, content_type: type)
        end

        def push_to_aws(filename, data, type) do
          complete = "#{UUID.uuid4()}/#{filename}"

          AppCount.Core.Tasker.start(fn ->
            env = AppCount.Config.env()
            path = "#{@path}/#{env}/#{complete}"

            ExAws.S3.put_object(@bucket, path, data, upload_opts(type))
            |> do_push
          end)

          complete
        end

        if Mix.env() in [:test, :integration] do
          def do_push(_request), do: nil
          def presigned_url(path), do: {:ok, path}
        else
          def do_push(request), do: ExAws.request(request, host: "s3-us-east-2.amazonaws.com")

          def presigned_url(path),
            do: ExAws.S3.presigned_url(ExAws.Config.new(:s3), :get, @bucket, path)
        end
      end

    caller =
      __CALLER__.module
      |> Module.concat(Upload)
      |> Module.concat(Macro.camelize(resource_name))

    Module.create(caller, contents, Macro.Env.location(__ENV__))
    caller
  end
end
