defmodule AppCount.Core.GenericRepo do
  defmodule NullTopic do
    @behaviour AppCount.Core.RepoTopicBehaviour
    @impl AppCount.Core.RepoTopicBehaviour
    def created(_meta, _source), do: :ok

    @impl AppCount.Core.RepoTopicBehaviour
    def changed(_meta, _source), do: :ok

    @impl AppCount.Core.RepoTopicBehaviour
    def deleted(_meta, _source), do: :ok
  end

  @default_topic AppCount.Core.GenericRepo.NullTopic
  #
  defmacro __using__(opts) do
    schema = Keyword.get(opts, :schema)
    preloads = Keyword.get(opts, :preloads, [])
    timeout = Keyword.get(opts, :timeout, 150_000)
    topic = Keyword.get(opts, :topic, @default_topic)

    quote do
      alias AppCount.Repo
      import Ecto.Query
      alias unquote(schema)

      @schema unquote(schema)
      @preloads unquote(preloads)
      @timeout unquote(timeout)
      @topic unquote(topic)

      def all(opts \\ []) do
        Repo.all(@schema, opts)
      end

      def get(id, preloads, opts) when is_integer(id) do
        Repo.get(@schema, id, opts)
        |> Repo.preload(preloads)
      end

      def get(id, opts \\ []) when is_integer(id) do
        Repo.get(@schema, id, opts)
      end

      def get_by(params, opts \\ []) do
        Repo.get_by(@schema, params, opts)
      end

      def get_aggregate(id) when is_integer(id) do
        aggregate_query(id)
        |> Repo.one(timeout: @timeout)
        |> put_aggregate_flag()
      end

      def get_aggregate(%{id: id}) when is_integer(id) do
        get_aggregate(id)
      end

      def aggregate(id) when is_integer(id) do
        if aggregate = get_aggregate(id) do
          {:ok, aggregate}
        else
          {:error, "Not Found #{@schema} id: #{id}"}
        end
      end

      defp aggregate_query(id) when is_integer(id) do
        from(
          o in @schema,
          where: o.id == ^id,
          preload: ^@preloads
        )
      end

      # if schema has an aggregate field
      defp put_aggregate_flag(%{aggregate: _aggregate} = aggregate) do
        %{aggregate | aggregate: true}
      end

      # otherwise
      defp put_aggregate_flag(aggregate) do
        aggregate
      end

      def insert(attrs, opts) when is_map(attrs) do
        %unquote(schema){}
        |> @schema.changeset(attrs)
        |> Repo.insert(opts)
        |> case do
          {:ok, result} ->
            created_event(result)
            {:ok, result}

          error ->
            error
        end
      end

      def insert(attrs) when is_map(attrs) do
        client_schema = Map.get(attrs, "prefix", "dasmen")

        %unquote(schema){}
        |> @schema.changeset(attrs)
        |> Repo.insert(prefix: client_schema)
        |> case do
          {:ok, result} ->
            created_event(result)
            {:ok, result}

          error ->
            error
        end
      end

      def update(%{} = schema, attrs, opts) when is_map(attrs) do
        changeset = @schema.changeset(schema, attrs)

        Repo.update(changeset, opts)
        |> case do
          {:ok, result} ->
            changed_event(result, changeset)
            {:ok, result}

          error ->
            error
        end
      end

      def update(%{} = schema, attrs) when is_map(attrs) do
        changeset = @schema.changeset(schema, attrs)

        Repo.update(changeset)
        |> case do
          {:ok, result} ->
            changed_event(result, changeset)
            {:ok, result}

          error ->
            error
        end
      end

      def delete(%AppCount.Core.ClientSchema{name: client_schema, attrs: id})
          when is_integer(id) do
        Repo.get(@schema, id, prefix: client_schema)
        |> Repo.delete(prefix: client_schema)
        |> case do
          {:ok, result} ->
            deleted_event(result)
            {:ok, result}

          error ->
            error
        end
      end

      def delete(id, opts \\ []) when is_integer(id) do
        Repo.get(@schema, id, opts)
        |> Repo.delete(opts)
        |> case do
          {:ok, result} ->
            deleted_event(result)
            {:ok, result}

          error ->
            error
        end
      end

      def count do
        Repo.count(@schema)
      end

      def one(query) do
        Repo.one(query, timeout: @timeout)
      end

      def first() do
        Repo.first(@schema)
      end

      def created_event(schema) do
        @topic.created(
          %{subject_name: @schema, subject_id: schema.id},
          __MODULE__
        )
      end

      def changed_event(schema, changeset) do
        @topic.changed(
          %{subject_name: @schema, subject_id: schema.id, changes: changeset.changes},
          __MODULE__
        )
      end

      def deleted_event(schema) do
        @topic.deleted(
          %{subject_name: @schema, subject_id: schema.id},
          __MODULE__
        )
      end

      # Defoverridable makes the given functions in the current module overridable
      # Without defoverridable, new definitions will not be picked up
      defoverridable insert: 1,
                     get: 1,
                     update: 2,
                     delete: 1,
                     created_event: 1,
                     changed_event: 2,
                     deleted_event: 1
    end
  end
end
