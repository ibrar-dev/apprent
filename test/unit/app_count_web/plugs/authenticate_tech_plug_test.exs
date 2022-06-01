defmodule AppCountWeb.Plugs.AuthenticateTechPlugTest do
  use AppCountWeb.ConnCase
  alias AppCount.Maintenance.TechRepo
  @moduletag :authenticate_tech_plug

  setup do
    tech_attrs = %{
      name: "Tech Name",
      email: "shared_email@example.com",
      phone_number: "1235551234",
      pass_code: UUID.uuid4(),
      active: true
    }

    {:ok, tech} = TechRepo.insert(tech_attrs)
    ~M[tech]
  end

  test "authentication failed with no token", ~M[conn] do
    conn =
      bypass_through(conn, AppCountWeb.Router, [:public_api])
      |> get("/")
      |> AppCountWeb.AuthenticateTechPlug.call([])

    assert conn.halted
    assert conn.resp_body =~ "Authentication Failed"
  end

  test "authentication passes with :tech_token", ~M[conn, tech] do
    {:ok, cert, _} = AppCount.Maintenance.cert_for_passcode(tech.pass_code)

    conn =
      bypass_through(conn, AppCountWeb.Router, [:public_api])
      |> get("/")
      |> put_session(:tech_token, cert)
      |> AppCountWeb.AuthenticateTechPlug.call([])

    assert not is_nil(conn.assigns.tech)
    assert conn.assigns.tech.id == tech.id
  end

  test "authentication passes with x-tech-token", ~M[conn, tech] do
    {:ok, cert, _} = AppCount.Maintenance.cert_for_passcode(tech.pass_code)

    conn =
      bypass_through(conn, AppCountWeb.Router, [:public_api])
      |> get("/")
      |> put_req_header("x-tech-token", cert)
      |> AppCountWeb.AuthenticateTechPlug.call([])

    assert not is_nil(conn.assigns.tech)
    assert conn.assigns.tech.id == tech.id
  end
end
