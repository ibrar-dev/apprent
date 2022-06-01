defmodule AppCount.EctoExtensions do
  defmacro jsonize_one(table, {:schema_fields, _, [arg]}) do
    fields = Macro.expand(arg, __CALLER__).__schema__(:fields)

    quote do
      jsonize_one(unquote(table), unquote(fields))
    end
  end

  defmacro jsonize_one(table, fields) do
    id_col = quote do: unquote(table).id
    fields = extract_fields(fields)
    args = jsonize_args(table, fields, nil) ++ [id_col]

    frag =
      "(array_agg(DISTINCT jsonb_build_object(#{jsonize_frag(fields)})) FILTER (WHERE ? IS NOT NULL))[1]"

    quote do
      fragment(unquote(frag), unquote_splicing(args))
    end
  end

  defmacro jsonize(table, fields, order \\ nil, ordering \\ "ASC")

  defmacro jsonize(table, {:schema_fields, _, [arg]}, order, ordering) do
    fields = Macro.expand(arg, __CALLER__).__schema__(:fields)

    quote do
      jsonize(unquote(table), unquote(fields), unquote(order), unquote(ordering))
    end
  end

  defmacro jsonize(table, fields, order, ordering) do
    id_col = quote do: unquote(table).id

    args = jsonize_args(table, extract_fields(fields), order) ++ [id_col]

    frag =
      "coalesce((jsonb_agg(#{if !order, do: "DISTINCT "}(SELECT xxxx FROM (SELECT #{
        question_marks(fields)
      }) AS xxxx)#{if order, do: " ORDER BY #{question_marks(order)} #{ordering}"}) FILTER (WHERE ? IS NOT NULL)), '[]'::jsonb)"

    quote do
      fragment(unquote(frag), unquote_splicing(args))
    end
  end

  defmacro cond_array(col) do
    quote do: fragment("CASE WHEN ? IS NULL THEN '[]' ELSE ? END", unquote(col), unquote(col))
  end

  defmacro array(col) do
    quote do
      fragment("array_remove(array_agg(DISTINCT (?)), NULL)", unquote(col))
    end
  end

  defmacro count_by(col, value) do
    query = "count(CASE WHEN ? = '#{value}' THEN 1 END)"

    quote do
      fragment(unquote(query), unquote(col))
    end
  end

  defmacro between(col, low, high) do
    quote do
      fragment("? BETWEEN ? AND ?", unquote(col), unquote(low), unquote(high))
    end
  end

  defmacro case_when(cond, if_true) do
    quote do
      fragment("CASE WHEN ? THEN ? END", unquote(cond), unquote(if_true))
    end
  end

  defmacro case_when(cond, if_true, if_false) do
    quote do
      fragment(
        "CASE WHEN ? THEN ? ELSE ? END",
        unquote(cond),
        unquote(if_true),
        unquote(if_false)
      )
    end
  end

  defmacro array_at(array, path) do
    p =
      path
      |> Enum.map(&"[#{&1}]")
      |> Enum.join()

    full = "?#{p}"

    quote do
      fragment(unquote(full), unquote(array))
    end
  end

  def schema_fields(module) do
    exclude = %{inserted_at: 1, updated_at: 1}

    module.__schema__(:fields)
    |> Enum.filter(&(!Map.get(exclude, &1)))
  end

  defp jsonize_frag(fields) do
    fields
    |> Enum.map(fn
      {name, _} -> "'#{name}', ?"
      f -> "'#{f}', ?"
    end)
    |> Enum.join(", ")
  end

  defp jsonize_args(table, fields, nil) do
    fields
    |> Enum.map(fn
      field when is_atom(field) ->
        quote do
          unquote(table).unquote(field)
        end

      {_, field} ->
        field

      field ->
        field
    end)
  end

  defp jsonize_args(table, fields, order) when is_list(order),
    do: jsonize_args(table, Enum.concat(fields, order), nil)

  defp jsonize_args(table, fields, order),
    do: jsonize_args(table, Enum.concat(fields, [order]), nil)

  defp extract_fields(fields) when is_atom(fields), do: fields.__schema__(:fields)
  defp extract_fields(fields), do: fields

  defp question_marks(fields) when is_list(fields) do
    fields
    |> Enum.map(fn
      {name, _} -> "? AS #{name}"
      _ -> "?"
    end)
    |> Enum.join(",")
  end

  defp question_marks(fields), do: question_marks([fields])
end
