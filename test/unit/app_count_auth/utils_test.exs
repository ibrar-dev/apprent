defmodule AppcountAuth.UtilsTest do
  use AppCount.Case
  alias AppCountAuth.Users.Admin

  test "Authorize user using feature_enabled disabled" do
    admin = %Admin{features: %{maintenance: true}}
    result = AppCountAuth.Utils.module_enabled?(admin, :session)
    assert result == {:error, :module_disabled}
  end

  test "Authorize user using feature_enabled enabled" do
    admin = %Admin{features: %{maintenance: true}}
    result = AppCountAuth.Utils.module_enabled?(admin, :maintenance)
    assert result == {:ok, :module_enabled}
  end
end
