defmodule AppCount.Crypto.Migrate do
  @public_exp 65537

  import Ecto.Query

  def migrate_keys({old_priv, old_pub}, schema, field_name, mod) do
    from(p in schema, select: [p.id, field(p, ^field_name)])
    |> AppCount.Repo.all()
    |> Enum.map(fn [id, val] ->
      decrypted =
        case Base.decode64(val) do
          :error -> val
          {:ok, decoded} -> :public_key.decrypt_private(decoded, key(old_pub, old_priv))
        end

      AppCount.Repo.get(mod, id)
      |> mod.changeset(%{field_name => decrypted})
      |> AppCount.Repo.update()
    end)
  end

  defp key(pub, priv) do
    {:RSAPrivateKey, "two-prime", pub, @public_exp, priv, nil, nil, nil, nil, nil, nil}
  end
end
