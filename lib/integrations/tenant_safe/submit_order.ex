defmodule TenantSafe.SubmitOrder do
  import XmlBuilder
  alias TenantSafe.Request
  alias TenantSafe.Applicant
  alias TenantSafe.Credentials
  import SweetXml

  @spec submit(Applicant.t(), Credentials.t()) :: %{order_id: String.t()} | {:error, any}
  def submit(%Applicant{} = application, %Credentials{} = config) do
    build_request(application, config)
    |> Request.submit()
    |> case do
      {:ok, body} ->
        body
        |> parse(namespace_conformant: true)
        |> xmap(order_id: ~x"//OrderId/text()"S)

      {:error, e} ->
        {:error, e}
    end
  end

  defp build_request(application, config) do
    element(
      :BackgroundCheck,
      %{userId: config.user_id, password: config.password},
      [
        background_search_element(application, config)
      ]
    )
    |> generate()
  end

  defp background_search_element(application, config) do
    element(
      :BackgroundSearchPackage,
      %{action: "submit", type: config.product_type},
      package(application)
    )
  end

  defp package(%{linked_orders: order_ids} = application) when is_list(order_ids) do
    application
    |> Map.put(:linked_orders, nil)
    |> package()
    |> Enum.concat([linked_applications(order_ids)])
  end

  defp package(application) do
    [
      element(:ReferenceId, "#{application.ref}"),
      personal_data(application),
      screenings(application)
    ]
  end

  defp linked_applications(order_ids) do
    element(:LinkedApplicants, Enum.map(order_ids, &element(:OrderId, &1)))
  end

  defp personal_data(application) do
    element(
      :PersonalData,
      [
        element(
          :PersonName,
          [
            element(:GivenName, application.first_name),
            element(:FamilyName, application.last_name)
          ]
        ),
        element(
          :DemographicDetail,
          [
            element(:GovernmentId, %{issuingAuthority: "SSN"}, application.ssn),
            element(:DateOfBirth, application.dob)
          ]
        ),
        element(
          :PostalAddress,
          %{type: "current"},
          [
            element(:PostalCode, application.zip),
            element(:Region, application.state),
            element(:Municipality, application.city),
            element(
              :DeliveryAddress,
              [
                element(:AddressLine, application.street)
              ]
            )
          ]
        ),
        element(:EmailAddress, application.email),
        element(:Telephone, application.phone)
      ]
    )
  end

  def screenings(application) do
    %{postback: url} = Application.get_env(:app_count, TenantSafe)

    element(
      :Screenings,
      %{useConfigurationDefaults: "Yes"},
      [
        element(
          :AdditionalItems,
          %{type: "x:monthly_rent"},
          [element(:Text, "#{application.rent}")]
        ),
        element(
          :AdditionalItems,
          %{type: "x:monthly_income"},
          [element(:Text, "#{application.income}")]
        ),
        element(
          :AdditionalItems,
          %{type: "x:decision_model"},
          [element(:Text, "REPORT")]
        ),
        element(
          :AdditionalItems,
          %{type: "x:postback_url"},
          [element(:Text, url)]
        ),
        element(
          :AdditionalItems,
          %{type: "x:embed_credentials"},
          [element(:Text, "TRUE")]
        ),
        element(
          :AdditionalItems,
          %{type: "x:decision_model"},
          [element(:Text, "SCORECARD_PRO")]
        ),
        element(
          :AdditionalItems,
          %{type: "x:return_xml_results"},
          [element(:Text, "yes")]
        )
      ]
    )
  end
end
