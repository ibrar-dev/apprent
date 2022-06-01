defmodule AppCount.Admins.Auth.Devices do
  alias AppCount.Admins.Device
  alias AppCount.Repo

  def register_device(%AppCount.Core.ClientSchema{
        name: client_schema,
        attrs: name
      }) do
    {public, private} = generate_keys()

    %Device{}
    |> Device.changeset(%{name: name, public_cert: public, private_cert: private})
    |> Repo.insert(prefix: client_schema)
    |> case do
      {:error, e} -> {:error, e}
      {:ok, device} -> Map.take(device, [:id, :private_cert])
    end
  end

  def verify_device(id, signed, message) do
    # TODO:SCHEMA pass client_schema
    case Repo.get(Device, id) do
      nil ->
        false

      device ->
        pub_key =
          device.public_cert
          |> :public_key.pem_decode()
          |> List.first()
          |> :public_key.pem_entry_decode()

        decoded = Base.decode64!(signed)
        :public_key.verify(message, :sha256, decoded, pub_key)
    end
  end

  defp generate_keys do
    private = :public_key.generate_key({:rsa, 1024, 65537})
    public = extract_public(private)
    public_pem = :public_key.pem_entry_encode(:SubjectPublicKeyInfo, public)
    private_pem = :public_key.pem_entry_encode(:RSAPrivateKey, private)
    {:public_key.pem_encode([public_pem]), :public_key.pem_encode([private_pem])}
  end

  defp extract_public(private) do
    [_, _, modulus, exp | _] = Tuple.to_list(private)
    {:RSAPublicKey, modulus, exp}
  end
end
