defmodule AppCount.Maintenance.TechRepoTest do
  use AppCount.DataCase
  alias AppCount.Maintenance.TechRepo

  setup do
    lionel = "Lionel Messi"

    tech_attrs = %{
      name: lionel,
      email: "shared_email@example.com",
      phone_number: "1235551234",
      active: true
    }

    ~M[tech_attrs, lionel]
  end

  describe "no name conflict" do
    test "insert", ~M[tech_attrs] do
      # When
      result = TechRepo.insert(tech_attrs)
      # Then
      assert {:ok, actual_tech} = result
      assert actual_tech.id
    end

    test "ignore inactive tech when checking for duplicates", ~M[tech_attrs] do
      _inactive_tech = TechRepo.insert(%{tech_attrs | active: false})
      # When
      result = TechRepo.insert(tech_attrs)
      # Then
      assert {:ok, actual_tech} = result
      assert actual_tech.id
    end

    test "update", ~M[tech_attrs] do
      {:ok, tech} = TechRepo.insert(tech_attrs)
      description = "Argentine footballer"
      # When
      result = TechRepo.update(tech, %{description: description})
      # Then
      assert {:ok, actual_tech} = result
      assert actual_tech.id
      assert actual_tech.description == description
    end

    test "update!", ~M[tech_attrs] do
      {:ok, tech} = TechRepo.insert(tech_attrs)
      description = "Argentine footballer"
      # When
      actual_tech = TechRepo.update!(tech, %{description: description})
      # Then
      assert actual_tech.id
      assert actual_tech.description == description
    end
  end

  describe "existing name conflict" do
    setup(%{tech_attrs: tech_attrs}) do
      {:ok, tech} = TechRepo.insert(tech_attrs)
      ~M[tech]
    end

    test "insert fails", ~M[tech_attrs] do
      {:error, changeset} = TechRepo.insert(tech_attrs)
      assert changeset.errors == [name: {"A Tech named Lionel Messi already exists", []}]
    end

    test "update fails: duplicate name", ~M[tech_attrs, lionel] do
      {:ok, ronaldo} = TechRepo.insert(%{tech_attrs | name: "Cristiano Ronaldo"})
      # When
      {:error, changeset} = TechRepo.update(ronaldo, %{name: lionel})
      assert changeset.errors == [name: {"A Tech named Lionel Messi already exists", []}]
    end

    test "update fails: duplicate name AND  missing email", ~M[tech_attrs, lionel] do
      {:ok, ronaldo} = TechRepo.insert(%{tech_attrs | name: "Cristiano Ronaldo"})
      # When
      {:error, changeset} = TechRepo.update(ronaldo, %{name: lionel, email: nil})

      assert changeset.errors == [
               name: {"A Tech named Lionel Messi already exists", []},
               email: {"can't be blank", [validation: :required]}
             ]
    end

    test "update! fails: missing email", ~M[tech_attrs, lionel] do
      {:ok, ronaldo} = TechRepo.insert(%{tech_attrs | name: "Cristiano Ronaldo"})
      # When
      assert_raise Ecto.InvalidChangesetError, ~r/email: \[\{\"can't be blank\"/, fn ->
        TechRepo.update!(ronaldo, %{name: lionel, email: nil})
      end
    end

    test "update! fails: duplicate name", ~M[tech_attrs, lionel] do
      {:ok, ronaldo} = TechRepo.insert(%{tech_attrs | name: "Cristiano Ronaldo"})
      # When
      assert_raise Ecto.InvalidChangesetError, ~r/A Tech named Lionel Messi already exists/, fn ->
        TechRepo.update!(ronaldo, %{name: lionel})
      end
    end

    test "update! fails: missing email  AND duplicate name", ~M[tech_attrs, lionel] do
      {:ok, ronaldo} = TechRepo.insert(%{tech_attrs | name: "Cristiano Ronaldo"})
      expected_error = Ecto.InvalidChangesetError

      # When
      function_under_test = fn -> TechRepo.update!(ronaldo, %{name: lionel, email: nil}) end

      assert_raise expected_error,
                   ~r/email: \[\{\"can't be blank\"/,
                   function_under_test

      assert_raise expected_error,
                   ~r/A Tech named Lionel Messi already exists/,
                   function_under_test
    end
  end
end
