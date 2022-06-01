defmodule BlueMoon.Requests.RequestSignature do
  alias BlueMoon.Auth
  import XmlBuilder

  @no_esign [
    "ACCMRQSTRES",
    "CHECKLST",
    "DAYTODAY",
    "MODRQSTRES",
    "PRSGUARANTY",
    "INVENTRY",
    "MOVEOUT",
    "PABETH",
    "PALANC",
    "VAWAADDEN",
    "VAWACERT",
    "VAWATRANSFER"
  ]

  defmodule Person do
    defstruct name: nil, email: nil, phone: nil
  end

  defmodule Parameters do
    @enforce_keys [:credentials, :owner, :residents, :lease_id]
    defstruct owner: nil,
              residents: nil,
              lease_id: nil,
              form_ids: nil,
              custom_form_ids: nil,
              credentials: nil,
              session: nil
  end

  @spec request(%Parameters{owner: %Person{}, lease_id: String.t(), residents: [%Person{}]}) ::
          String.t()
  def request(%Parameters{form_ids: nil} = params) do
    params
    |> build_params
    |> request
  end

  def request(%Parameters{} = params) do
    request = [
      element("LeaseId", params.lease_id),
      element("OwnerRep", person_element(params.owner)),
      element("Residents", Enum.map(params.residents, &element("item", nil, person_element(&1)))),
      element("LeaseForms", form_id_elements(params.form_ids)),
      element("CustomForms", form_id_elements(params.custom_form_ids)),
      element("SendOwnerRepNotices", true)
    ]

    {params.session, request}
  end

  def build_params(%Parameters{credentials: credentials} = params) do
    case Auth.session_id(credentials) do
      {:ok, s} ->
        {:ok, form_ids} = BlueMoon.list_forms(s)
        {:ok, custom_form_ids} = BlueMoon.list_custom_forms(s)
        Map.merge(params, %{form_ids: form_ids, session: s, custom_form_ids: custom_form_ids})

      _e ->
        params
    end
  end

  defp form_id_elements(ids) do
    Enum.map(ids -- @no_esign, &element("item", [element("Id", nil, "#{&1}")]))
  end

  defp person_element(%Person{} = person) do
    [element("Name", person.name), element("Email", person.email), element("Phone", person.phone)]
  end
end
