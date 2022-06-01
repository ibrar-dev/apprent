defmodule AppCountWeb.LiveHelpersTest do
  use AppCount.Case
  alias AppCountWeb.LiveHelpers

  test "titleize" do
    # When
    result = LiveHelpers.titleize("blah_blah")
    # Then
    assert result == "Blah Blah"
  end
end
