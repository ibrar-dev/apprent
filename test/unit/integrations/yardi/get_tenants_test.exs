defmodule Yardi.Gateway.GetTenantsTest do
  use AppCount.Case
  alias AppCount.Support.HTTPClient
  @moduletag :yardi_gateway_get_tenants

  @get_tenants_response File.read!(
                          Path.expand(
                            "../../resources/Yardi/get_tenants.xml",
                            __DIR__
                          )
                        )

  @parsed_get_tenants [
    %{
      email: "pughrlexis@m9t5q.com",
      first_name: "RLexis",
      last_name: "Pugh",
      lease_from_date: ~D[2021-02-17],
      lease_to_date: ~D[2022-02-16],
      move_in_date: ~D[2021-02-17],
      move_out_date: nil,
      notice_date: nil,
      p_code: "p0207292",
      phone: "7065737971",
      status: "Future",
      t_code: "t0044164",
      unit_code: "4350-117"
    },
    %{
      email: nil,
      first_name: "Leonard",
      last_name: "Pearson",
      lease_from_date: ~D[2019-08-01],
      lease_to_date: ~D[2020-07-31],
      move_in_date: ~D[2019-08-01],
      move_out_date: ~D[2021-04-30],
      notice_date: ~D[2021-01-11],
      p_code: "p0158278",
      phone: "3347777654",
      status: "Notice",
      t_code: "t0037428",
      unit_code: "4300-115"
    },
    %{
      email: nil,
      first_name: "Ruth",
      last_name: "Stanley*",
      lease_from_date: ~D[2020-10-01],
      lease_to_date: ~D[2021-10-01],
      move_in_date: ~D[2013-02-01],
      move_out_date: nil,
      notice_date: nil,
      p_code: "p0065485",
      phone: "2152694991",
      status: "Current",
      t_code: "t0019237",
      unit_code: "204"
    },
    %{
      email: "aswinehart89@g8p3c.com",
      first_name: "Amanda",
      last_name: "Swinehart",
      lease_from_date: ~D[2020-12-31],
      lease_to_date: ~D[2021-12-30],
      move_in_date: ~D[2020-11-30],
      move_out_date: nil,
      notice_date: nil,
      p_code: "p0197927",
      phone: "2159323035",
      status: "Current",
      t_code: "t0019507",
      unit_code: "205"
    },
    %{
      email: "rgegner1992@g8p3c.com",
      first_name: "Rachel",
      last_name: "Gegner",
      lease_from_date: ~D[2020-08-01],
      lease_to_date: ~D[2021-08-01],
      move_in_date: ~D[2018-08-02],
      move_out_date: nil,
      notice_date: nil,
      p_code: "p0065486",
      phone: "2674182278",
      status: "Current",
      t_code: "t0019238",
      unit_code: "206"
    },
    %{
      email: "mrsballard1983@g8p3c.com",
      first_name: "Stephanie",
      last_name: "Ballard",
      lease_from_date: ~D[2020-06-01],
      lease_to_date: ~D[2021-06-01],
      move_in_date: ~D[2015-07-01],
      move_out_date: nil,
      notice_date: nil,
      p_code: "p0065487",
      phone: "2159545856",
      status: "Current",
      t_code: "t0019239",
      unit_code: "207"
    },
    %{
      email: "rtheard2@g8p3c.com",
      first_name: "Reggie",
      last_name: "Heard",
      lease_from_date: ~D[2020-11-01],
      lease_to_date: ~D[2021-11-01],
      move_in_date: ~D[2018-11-01],
      move_out_date: nil,
      notice_date: nil,
      p_code: "p0065610",
      phone: "3022982545",
      status: "Current",
      t_code: "t0019328",
      unit_code: "208"
    },
    %{
      email: nil,
      first_name: "Annie",
      last_name: "Roberts",
      lease_from_date: ~D[2021-07-08],
      lease_to_date: ~D[2022-07-31],
      move_in_date: ~D[2021-07-08],
      move_out_date: nil,
      notice_date: nil,
      p_code: "p0264908",
      phone: nil,
      status: "Applicant",
      t_code: "t0051796",
      unit_code: "4-2667A"
    }
  ]

  test "get_tenants" do
    credentials = %{
      username: "",
      password: "",
      platform: "",
      server_name: "",
      db: "",
      url: "",
      entity: "",
      interface: "",
      gl_account: ""
    }

    HTTPClient.initialize([@get_tenants_response])
    result = Yardi.Gateway.get_tenants("1x1x", credentials)
    HTTPClient.stop()
    assert result == {:ok, @parsed_get_tenants}
  end
end
