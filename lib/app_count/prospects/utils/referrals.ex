defmodule AppCount.Prospects.Utils.Referrals do
  alias AppCount.Repo
  alias AppCount.Prospects.Referral

  @spec record_referral(%Plug.Conn{}) :: {:ok, %Referral{}} | {:error, %Ecto.Changeset{}}
  def record_referral(conn) do
    case readable_referral(conn.query_params) do
      nil ->
        nil

      referral ->
        %{ip_address: get_user_ip(conn), referrer: referral}
        |> create_referral
    end
  end

  @spec create_referral(map()) :: {:ok, %Referral{}} | {:error, %Ecto.Changeset{}}
  def create_referral(params) do
    %Referral{}
    |> Referral.changeset(params)
    |> Repo.insert()
  end

  defp get_user_ip(conn) do
    get_forwarding_header(conn) || convert_ip(conn.remote_ip)
  end

  defp get_forwarding_header(conn) do
    List.first(Plug.Conn.get_req_header(conn, "x-forwarded-for"))
  end

  defp convert_ip(ip_tuple) do
    ip_tuple
    |> Tuple.to_list()
    |> Enum.join(".")
  end

  defp readable_referral(%{"referral" => referral}), do: referral
  defp readable_referral(_params), do: nil
end
