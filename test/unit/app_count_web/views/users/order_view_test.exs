defmodule AppCountWeb.Users.OrderViewTest do
  use AppCount.DataCase
  alias AppCountWeb.Users.OrderView

  setup do
    notes = [
      %{"id" => 238_391, "image" => nil, "text" => "balrgh"},
      %{
        "id" => 238_392,
        "image" => "D8F44DEF-D3B9-42B3-AAF1-019347A044F7",
        "text" => nil
      },
      %{"id" => 238_393, "image" => nil, "text" => "flower dog "},
      %{
        "id" => 238_394,
        "image" => "BFD8AABB-133F-4872-BB19-F1F5DD50A3EC",
        "text" =>
          "And we used to sleep on the beach here, sleep overnight. They don't do that anymore."
      }
    ]

    amazon_url = "https://s3-us-east-2.amazonaws.com/appcount-maintenance/notes/"

    env = AppCount.env(:environment)

    ~M[notes, amazon_url,env]
  end

  describe "text_note/1" do
    test "no text" do
      result = OrderView.text_note([])

      assert result == ""
    end

    test "one note" do
      notes = [%{"id" => 238_391, "image" => nil, "text" => "balrgh"}]

      result = OrderView.text_note(notes)

      assert result == "balrgh"
    end

    test "one note with no text" do
      notes = [%{"id" => 238_391, "image" => nil, "text" => nil}]

      result = OrderView.text_note(notes)

      assert result == ""
    end

    test "multiple notes", ~M[notes] do
      result = OrderView.text_note(notes)

      assert result ==
               "And we used to sleep on the beach here, sleep overnight. They don't do that anymore."
    end
  end

  describe "image_note_url/1" do
    test "handles nil" do
      result = OrderView.image_note_url(nil)

      assert result == "/images/no-image.gif"
    end

    test "0 notes" do
      result = OrderView.image_note_url([])

      assert result == "/images/no-image.gif"
    end

    test "1 note with nil image_url" do
      notes = [%{"id" => 238_391, "image" => nil, "text" => "balrgh\r\n"}]

      # when
      result = OrderView.image_note_url(notes)

      assert result == "/images/no-image.gif"
    end

    test "1 note", ~M[amazon_url, env] do
      notes = [%{"id" => 238_391, "image" => "dog4DJFKG", "text" => "balrgh\r\n"}]
      id = 238_391
      filename = "dog4DJFKG"

      # when
      result = OrderView.image_note_url(notes)

      assert result == amazon_url <> "#{env}/#{id}/#{filename}"
    end

    test "3 notes", ~M[notes, amazon_url, env] do
      last_note = List.last(notes)

      id = last_note["id"]
      filename = last_note["image"]

      # when
      result = OrderView.image_note_url(notes)

      assert result == amazon_url <> "#{env}/#{id}/#{filename}"
    end
  end
end
