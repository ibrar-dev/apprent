defmodule AppCount.Core.SchemaHelperTest do
  use AppCount.Case, async: true
  alias AppCount.Core.SchemaHelper

  describe "changeset clean-up email" do
    test "empty email" do
      result = SchemaHelper.cleanup_email(%{email: ""})
      refute result.email
    end

    test "nil email" do
      result = SchemaHelper.cleanup_email(%{email: nil})
      refute result.email
    end

    test "valid email" do
      result = SchemaHelper.cleanup_email(%{email: "Mickey@mouse.com"})
      assert result.email == "Mickey@mouse.com"
    end

    test "email with leading space" do
      result = SchemaHelper.cleanup_email(%{email: "  Mickey@mouse.com"})
      assert result.email == "Mickey@mouse.com"
    end

    test "email with trailing spaces" do
      result = SchemaHelper.cleanup_email(%{email: "Mickey@mouse.com   "})
      assert result.email == "Mickey@mouse.com"
    end

    test "email with trailing space and other junk" do
      result = SchemaHelper.cleanup_email(%{email: " Mickey@mouse.com -- donald@duck.com"})
      assert result.email == "Mickey@mouse.com"
    end
  end
end
