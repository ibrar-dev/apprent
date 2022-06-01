defmodule AppCount.Properties.LetterTemplatesTest do
  use AppCount.DataCase
  import AppCount.LeaseHelper
  alias AppCount.Properties
  @moduletag :properties_letter_templates

  setup do
    property = insert(:property)
    lease = insert_lease(%{property: property})

    template_body = """
    <p>Dear <a href="APPRENT_SC_FULL_NAME" class="wysiwyg-mention" data-mention data-value="FULL_NAME">@FULL_NAME</a>&nbsp;</p>
    """

    template = insert(:letter_template, body: template_body, property: property)
    {:ok, property: property, template: template, lease: lease}
  end

  test "get_letter_templates", %{property: property, template: template} do
    [result] = Properties.get_letter_templates(property.id)
    assert result.id == template.id
    assert result.name == template.name
    assert result.body == template.body
  end

  test "create_letter_template", %{property: property} do
    %{"name" => "Creation template", "body" => "Blah Blah Blahblah", "property_id" => property.id}
    |> Properties.create_letter_template()

    assert Repo.get_by(Properties.LetterTemplate, name: "Creation template")
  end

  test "update_letter_template", %{template: template} do
    Properties.update_letter_template(template.id, %{"name" => "ABCDEFG"})
    assert Repo.get(Properties.LetterTemplate, template.id).name == "ABCDEFG"
  end

  test "delete_letter_template", %{template: template} do
    Properties.delete_letter_template(template.id)
    refute Repo.get(Properties.LetterTemplate, template.id)
  end
end
