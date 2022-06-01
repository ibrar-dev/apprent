defmodule AppCount.Leasing.BlueMoon.CreateLease do
  alias AppCount.Repo
  alias AppCount.Properties.Unit
  alias AppCount.Leasing.ExternalLease
  alias AppCount.Leasing.ExternalLeaseRepo
  alias BlueMoon.Requests.RequestSignature
  alias AppCount.Core.ClientSchema

  @default_email Application.compile_env(:app_count, :test_email)

  def create(%ClientSchema{
        name: client_schema,
        attrs: %ExternalLease{provider: "BlueMoon"} = external_lease
      }) do
    %{property_id: property_id, phone: phone} =
      property_params(ClientSchema.new(client_schema, external_lease.unit_id))

    credentials =
      AppCount.Leasing.BlueMoon.Credentials.credentials_for_property(
        ClientSchema.new(client_schema, property_id)
      )

    {lease_params, custom} = BlueMoon.Data.Xml.to_xml(external_lease.parameters)

    create_params = %BlueMoon.Requests.CreateLease.Parameters{
      property_id: credentials.property_id,
      lease_params: lease_params,
      custom_params: custom
    }

    with {:ok, form_id} <- BlueMoon.create_lease(credentials, create_params),
         {:ok, external_lease} <-
           ExternalLeaseRepo.update(external_lease, %{external_id: form_id}, prefix: client_schema),
         {:ok, sig_id} <- submit_signature(external_lease, phone, credentials),
         {:ok, external_lease} <- update_signators(external_lease) do
      ExternalLeaseRepo.update(external_lease, %{signature_id: sig_id}, prefix: client_schema)
    else
      e -> e
    end
  end

  def property_params(%ClientSchema{
        name: client_schema,
        attrs: unit_id
      }) do
    unit =
      Repo.get(Unit, unit_id, prefix: client_schema)
      |> Repo.preload(:property)

    %{property_id: unit.property_id, phone: unit.property.phone}
  end

  def submit_signature(external_lease, property_phone, credentials) do
    %RequestSignature.Parameters{
      owner: %RequestSignature.Person{
        name: external_lease.admin.name,
        email: external_lease.admin.email,
        phone: property_phone
      },
      residents:
        Enum.map(
          external_lease.parameters.residents,
          &%RequestSignature.Person{name: &1.name, email: email_address(&1), phone: &1.phone}
        ),
      lease_id: external_lease.external_id,
      credentials: credentials
    }
    |> BlueMoon.request_esignature()
  end

  # Is this strange? Yes but it is necessary to suppress a compiler warning
  # See https://elixirforum.com/t/warning-this-check-guard-will-always-yield-the-same-result-should-i-do-this-differently/9324/2
  defp email_address(person), do: email_address(person, @default_email)
  defp email_address(person, nil), do: person.email
  defp email_address(_, default_email), do: default_email

  defp update_signators(%AppCount.Leasing.ExternalLease{} = lease) do
    sig =
      (Map.get(lease.parameters, :residents) || Map.get(lease.parameters, "residents"))
      |> Enum.into(%{}, &{&1["name"], nil})

    ExternalLeaseRepo.update(lease, %{signators: sig}, prefix: lease.__meta__.prefix)
  end
end
