defmodule BlueMoon.Requests.GetLeasePDF do
  import XmlBuilder
  alias BlueMoon.Auth
  alias BlueMoon.Credentials

  @spec request(BlueMoon.auth(), String.t()) :: list()
  def request(%Credentials{} = credentials, lease_id) do
    case Auth.session_id(credentials) do
      {:ok, s} -> request(s, lease_id)
      e -> e
    end
  end

  def request(session, lease_id) do
    {:ok, form_ids} = BlueMoon.list_forms(session)
    {:ok, custom_form_ids} = BlueMoon.list_custom_forms(session)

    [
      element("LeaseId", lease_id),
      element("LeaseForms", get_form_elements(form_ids)),
      element("CustomForms", get_form_elements(custom_form_ids))
    ]
  end

  defp get_form_elements(form_ids) do
    Enum.map(form_ids, &element("item", [element("Id", &1)]))
  end
end
