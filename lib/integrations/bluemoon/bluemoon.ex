defmodule BlueMoon do
  import XmlBuilder
  import SweetXml
  alias BlueMoon.Request
  alias BlueMoon.Credentials
  alias BlueMoon.Requests.RequestSignature
  alias BlueMoon.Requests.ExecuteLease
  alias BlueMoon.Requests.CreateLease
  alias BlueMoon.Requests.EditLease
  alias BlueMoon.Requests.GetLeasePDF

  @type auth :: %Credentials{} | String.t()
  @type response :: {:ok, String.t()} | {:error, String.t()}

  @spec create_lease(auth, %CreateLease.Parameters{}) :: response
  def create_lease(credentials_or_session, %CreateLease.Parameters{} = params) do
    Request.make_request(
      credentials_or_session,
      "CreateLease",
      CreateLease.request(params),
      ~x"//ns1:CreateLeaseResponse/CreateLeaseResult/text()"S
    )
  end

  @spec edit_lease(auth, %EditLease.Parameters{}) :: response
  def edit_lease(credentials_or_session, %EditLease.Parameters{} = params) do
    Request.make_request(
      credentials_or_session,
      "EditLease",
      EditLease.request(params),
      ~x"//ns1:EditLeaseResponse/EditLeaseResult/text()"S
    )
  end

  @spec get_default_lease(auth) :: {:ok, String.t()} | {:error, String.t()}
  def get_default_lease(credentials_or_session) do
    Request.make_request(
      credentials_or_session,
      "GetDefaultLeaseXMLData",
      [],
      ~x"//ns1:GetDefaultLeaseXMLDataResponse/GetDefaultLeaseXMLDataResult/text()"S
    )
  end

  @spec list_default_fields(auth) :: {:ok, String.t()} | {:error, String.t()}
  def list_default_fields(credentials_or_session) do
    Request.make_request(
      credentials_or_session,
      "ListDefaultFields",
      [],
      {
        ~x"//ns1:ListDefaultFieldsResponse/ListDefaultFieldsResult/item"l,
        [name: ~x"./Name/text()"S, type: ~x"./Type/@xsi:nil"S, length: ~x"./Length/@xsi:nil"S]
      }
    )
  end

  @spec list_fields(auth) :: {:ok, String.t()} | {:error, String.t()}
  def list_fields(credentials_or_session) do
    Request.make_request(
      credentials_or_session,
      "ListFields",
      [],
      {
        ~x"//ns1:ListFieldsResponse/ListFieldsResult/item"l,
        [name: ~x"./Name/text()"S, type: ~x"./Type/@xsi:nil"S, length: ~x"./Length/@xsi:nil"S]
      }
    )
  end

  @spec request_esignature(%RequestSignature.Parameters{}) :: response
  def request_esignature(params) do
    {session, request} = RequestSignature.request(params)

    Request.make_request(
      session,
      "RequestEsignature",
      request,
      ~x"//ns1:RequestEsignatureResponse/RequestEsignatureResult/text()"S
    )
  end

  @spec execute_lease(auth, String.t(), String.t()) :: {:ok, String.t()} | {:error, String.t()}
  def execute_lease(credentials_or_session, sig_id, signer) do
    Request.make_request(
      credentials_or_session,
      "ExecuteLease",
      ExecuteLease.request(sig_id, signer),
      ~x"//ns1:ExecuteLeaseResponse/ExecuteLeaseResult/text()"S
    )
  end

  @spec get_lease_data(auth, String.t()) :: {:ok, String.t()} | {:error, String.t()}
  def get_lease_data(credentials_or_session, lease_id) do
    Request.make_request(
      credentials_or_session,
      "GetLeaseXMLData",
      element("LeaseId", nil, lease_id),
      ~x"//ns1:GetLeaseXMLDataResponse/GetLeaseXMLDataResult/text()"S
    )
  end

  @spec get_signature_status(auth, String.t()) :: {:ok, String.t()} | {:error, String.t()}
  def get_signature_status(credentials_or_session, signature_id) do
    Request.make_request(
      credentials_or_session,
      "GetEsignatureData",
      element("EsignatureId", nil, signature_id),
      {
        ~x"//ns1:GetEsignatureDataResponse/GetEsignatureDataResult/Signers/item"l,
        [name: ~x"./Name/text()"S, date_signed: ~x"./DateSigned/text()"S]
      }
    )
  end

  @spec get_signature_pdf(auth, String.t()) :: {:ok, String.t()} | {:error, String.t()}
  def get_signature_pdf(credentials_or_session, signature_id) do
    Request.make_request(
      credentials_or_session,
      "GetEsignaturePDF",
      element("EsignatureId", nil, signature_id),
      ~x"//ns1:GetEsignaturePDFResponse/GetEsignaturePDFResult/text()"S
    )
  end

  @spec get_lease_pdf(auth, String.t()) :: {:ok, String.t()} | {:error, String.t()}
  def get_lease_pdf(credentials_or_session, lease_id) do
    Request.make_request(
      credentials_or_session,
      "GetLeasePDF",
      GetLeasePDF.request(credentials_or_session, lease_id),
      ~x"//ns1:GetLeasePDFResponse/GetLeasePDFResult/text()"S
    )
  end

  @spec get_execution_date(auth, String.t()) :: {:ok, String.t()} | {:error, String.t()}
  def get_execution_date(credentials_or_session, signature_id) do
    Request.make_request(
      credentials_or_session,
      "GetEsignatureData",
      element("EsignatureId", nil, signature_id),
      ~x"//ns1:GetEsignatureDataResponse/GetEsignatureDataResult/DateExecuted/text()"S
    )
  end

  def list_properties(credentials_or_session) do
    Request.make_request(
      credentials_or_session,
      "ListProperties",
      [],
      {
        ~x"//ns1:ListPropertiesResponse/ListPropertiesResult/item"l,
        [name: ~x"./Name/text()"S, id: ~x"./Id/text()"S, type: ~x"./Type/text()"S]
      }
    )
  end

  def list_units(credentials_or_session) do
    Request.make_request(
      credentials_or_session,
      "ListUnits",
      [],
      {
        ~x"//ns1:ListUnitsResponse/ListUnitsResult/item"el,
        :transform
      }
    )
  end

  def list_forms(credentials_or_session) do
    Request.make_request(
      credentials_or_session,
      "ListForms",
      [],
      ~x"//ns1:ListFormsResponse/ListFormsResult/item/Id/text()"Sl
    )
  end

  def list_custom_forms(credentials_or_session) do
    Request.make_request(
      credentials_or_session,
      "ListCustomForms",
      [],
      ~x"//ns1:ListCustomFormsResponse/ListCustomFormsResult/item/Id/text()"Sl
    )
  end
end
