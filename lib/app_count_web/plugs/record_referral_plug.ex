defmodule AppCountWeb.RecordReferralPlug do
  @deps %{referrals: AppCount.Prospects.Utils.Referrals}

  def init(default), do: default

  def call(conn, _default) do
    AppCount.Core.Tasker.start(fn ->
      @deps.referrals.record_referral(conn)
    end)

    conn
  end
end
