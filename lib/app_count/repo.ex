defmodule AppCount.Repo do
  defmodule Priv do
    import Ecto.Query

    def nil_safe_get_by(module, args) do
      Enum.reduce(
        args,
        from(x in module),
        fn
          {field, nil}, query -> where(query, [x], is_nil(field(x, ^field)))
          {field, value}, query -> where(query, [x], field(x, ^field) == ^value)
        end
      )
      |> AppCount.Repo.one()
    end

    def reset_id(module) do
      source = module.__schema__(:source)

      Ecto.Adapters.SQL.query!(
        AppCount.Repo,
        "SELECT setval('dasmen.#{source}_id_seq', (SELECT max(id) FROM dasmen.#{source}), true)",
        [],
        # temporary hack fix, this will not be needed very very soon
        prefix: "dasmen"
      )
    end
  end

  use AppCount.MultiRepo, otp_app: :app_count, adapter: Ecto.Adapters.Postgres
  use Scrivener, page_size: 9
  # , only: [limit: 3]
  import Ecto.Query

  require Logger

  def nil_safe_get_by(module, args) do
    Priv.nil_safe_get_by(module, args)
  end

  def reset_id(module), do: Priv.reset_id(module)

  def explain_analyze(query) do
    if AppCount.env().environment == :dev do
      {query_string, vars} = Ecto.Adapters.SQL.to_sql(:all, AppCount.Repo, query)

      result =
        Ecto.Adapters.SQL.query!(AppCount.Repo, "EXPLAIN ANALYZE #{query_string}", vars,
          timeout: 2_000_000
        )
        |> Map.get(:rows)
        |> List.flatten()
        |> Enum.join("\n")

      File.write("explain.txt", result)
      query
    else
      raise "cannot run EXPLAIN ANALYZE in non-dev environment"
    end
  end

  def count(table) do
    aggregate(table, :count, :id)
  end

  def first(table) do
    from(
      t in table,
      limit: 1,
      order_by: [asc: :inserted_at]
    )
    |> one()
  end

  def last(table, count \\ 1) do
    last = count(table)
    offset = last - count

    from(
      t in table,
      offset: ^offset,
      limit: ^count,
      order_by: [asc: :inserted_at]
    )
    |> all()
  end
end
