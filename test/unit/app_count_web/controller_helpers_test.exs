defmodule AppCountWeb.ControllerHelpersTest do
  use ExUnit.Case, async: true
  alias AppCountWeb.ControllerHelpers

  describe "to_integers/1" do
    test "zero" do
      result = ControllerHelpers.to_integers("")
      assert result == []
    end

    test "one" do
      result = ControllerHelpers.to_integers("23")
      assert result == [23]
    end

    test "many" do
      result = ControllerHelpers.to_integers("23,99,1029")
      assert result == [23, 99, 1029]
    end
  end
end
