defmodule Google.MaintenanceTest do
  use AppCount.DataCase
  alias Google.Maintenance
  import ExUnit.CaptureLog

  defmodule HTTPoisonParrot do
    use TestParrot
    parrot(:http, :post, :error)
  end

  describe "unsafe_post/4" do
    test "failure" do
      result = Maintenance.unsafe_post("data", "headers", :single, HTTPoisonParrot)
      assert result == :unable_to_get_id
    end

    # requires test_parrot 3.0.3, not yet released
    # test "exception ArgumentError" do
    #   HTTPoisonParrot.say_post(fn -> raise ArgumentError end)
    #   result = Maintenance.unsafe_post("data", "headers", HTTPoisonParrot)
    #
    #   assert result == :unable_to_get_id
    # end
  end

  describe "safe_post/4" do
    setup do
      crash_fn = fn _data, _headers, _type, _module -> raise ArgumentError end
      ~M[crash_fn]
    end

    test "succeeds" do
      success_fn = fn _data, _headers, _type, _module -> "success" end

      result = Maintenance.safe_post("data", "headers", :multi, success_fn)
      assert result == "success"
    end

    test "fails writting to log", ~M[crash_fn] do
      log_messages =
        capture_log(fn ->
          Maintenance.safe_post("data", "headers", crash_fn)
        end)

      assert log_messages =~
               ~s{[error] Google.Maintenance ArgumentError data: \"data\", headers: \"headers\"}
    end

    test "fails returns :unable_to_get_id", ~M[crash_fn] do
      result = Maintenance.safe_post("data", "headers", crash_fn)
      assert result == :unable_to_get_id
    end
  end

  describe "build_safe_note/1" do
    test "removes double quotes" do
      # When
      note = ~s("Hello there, General Kenobi")

      # then
      result = Maintenance.build_safe_note(note)

      assert result == "Hello there, General Kenobi"
    end

    test "removes backslash but leaves escape characters" do
      # When
      note =
        ~s(I don't like sand.\tIt's coarse \\and \\rough and irritating\\\\\ and it "gets" everywhere.)

      # then
      result = Maintenance.build_safe_note(note)

      assert result ==
               "I don't like sand.\tIt's coarse and rough and irritating and it gets everywhere."
    end

    test "removes extra new line" do
      # When
      note =
        ~s(I don't like sand.\tIt's coarse \\and \\rough and irritating\n and it "gets" everywhere.\n)

      # Then
      result = Maintenance.build_safe_note(note)

      assert result ==
               "I don't like sand.\tIt's coarse and rough and irritating and it gets everywhere."
    end

    test "removes emoji and leaves characters with diacritical marks" do
      # When
      note = ~s(foobar ñ \u2754)

      # Then
      result = Maintenance.build_safe_note(note)

      assert result == "foobar ñ "
    end
  end
end
