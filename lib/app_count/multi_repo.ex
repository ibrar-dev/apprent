defmodule AppCount.MultiRepo do
  @type t :: module

  @doc false
  defmacro __using__(opts) do
    quote bind_quoted: [opts: opts] do
      use Ecto.Repo, Keyword.put_new(opts, :read_only, true)

      require Logger

      @unsafe_db_warning Application.get_env(:triplex, :unsafe_db_warning)
      @default_schema opts[:default_schema] || "dasmen"

      def insert(struct, opts \\ []) do
        opts = safe_db_schema(opts)

        Ecto.Repo.Schema.insert(
          __MODULE__,
          get_dynamic_repo(),
          struct,
          with_default_options(:insert, opts)
        )
      end

      def update(struct, opts \\ []) do
        opts = safe_db_schema(opts)

        Ecto.Repo.Schema.update(
          __MODULE__,
          get_dynamic_repo(),
          struct,
          with_default_options(:update, opts)
        )
      end

      def insert_or_update(changeset, opts \\ []) do
        opts = safe_db_schema(opts)

        Ecto.Repo.Schema.insert_or_update(
          __MODULE__,
          get_dynamic_repo(),
          changeset,
          with_default_options(:insert_or_update, opts)
        )
      end

      def delete(struct, opts \\ []) do
        opts = safe_db_schema(opts)

        Ecto.Repo.Schema.delete(
          __MODULE__,
          get_dynamic_repo(),
          struct,
          with_default_options(:delete, opts)
        )
      end

      def insert!(struct, opts \\ []) do
        opts = safe_db_schema(opts)

        Ecto.Repo.Schema.insert!(
          __MODULE__,
          get_dynamic_repo(),
          struct,
          with_default_options(:insert, opts)
        )
      end

      def update!(struct, opts \\ []) do
        opts = safe_db_schema(opts)

        Ecto.Repo.Schema.update!(
          __MODULE__,
          get_dynamic_repo(),
          struct,
          with_default_options(:update, opts)
        )
      end

      def insert_or_update!(changeset, opts \\ []) do
        opts = safe_db_schema(opts)

        Ecto.Repo.Schema.insert_or_update!(
          __MODULE__,
          get_dynamic_repo(),
          changeset,
          with_default_options(:insert_or_update, opts)
        )
      end

      def delete!(struct, opts \\ []) do
        opts = safe_db_schema(opts)

        Ecto.Repo.Schema.delete!(
          __MODULE__,
          get_dynamic_repo(),
          struct,
          with_default_options(:delete, opts)
        )
      end

      def insert_all(schema_or_source, entries, opts \\ []) do
        opts = safe_db_schema(opts)

        Ecto.Repo.Schema.insert_all(
          __MODULE__,
          get_dynamic_repo(),
          schema_or_source,
          entries,
          with_default_options(:insert_all, opts)
        )
      end

      def update_all(queryable, updates, opts \\ []) do
        opts = safe_db_schema(opts)
        Ecto.Repo.Queryable.update_all(get_dynamic_repo(), queryable, updates, opts)
      end

      def delete_all(queryable, opts \\ []) do
        opts = safe_db_schema(opts)
        Ecto.Repo.Queryable.delete_all(get_dynamic_repo(), queryable, opts)
      end

      def prepare_query(operation, %{from: %{source: {"schema_migrations", _}}} = query, opts) do
        {query, opts}
      end

      def prepare_query(operation, query, opts) do
        opts = safe_db_schema(opts)
        {query, opts}
      end

      defoverridable prepare_query: 3

      def safe_db_schema(opts = [prefix: client_schema]) when not is_nil(client_schema), do: opts

      def safe_db_schema(opts) do
        if @unsafe_db_warning do
          Logger.warn(Exception.format_stacktrace(), unsafe_db_call: true)
        end

        Keyword.put_new(opts, :prefix, @default_schema)
      end
    end
  end
end
