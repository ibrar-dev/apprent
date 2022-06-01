defmodule AppCount.AccessServer.AccessServerTest do
  @moduledoc false
  use AppCount.DataCase
  alias AppCount.Admins.AccessServer

  defmodule LoaderParrot do
    use TestParrot
    parrot(:loader, :property_ids_for, [7, 8, 9])
  end

  describe "property_ids_for, stub Loader" do
    setup do
      state = %AccessServer{repo: LoaderParrot}
      admin = %{id: 23}
      original_property_ids = [7, 8, 9]
      changed_property_ids = [1000, 2000, 3000]

      ~M[state, admin, original_property_ids, changed_property_ids]
    end

    test "adds to cache", ~M[ original_property_ids] do
      state = %AccessServer{repo: LoaderParrot, admins: %{}}
      admin = %{id: 23}

      # When
      {:reply, property_ids, state} =
        AccessServer.handle_call({:property_ids_for, admin}, __MODULE__, state)

      assert_receive {:property_ids_for,
                      %AppCount.Core.ClientSchema{attrs: %{id: 23}, name: "dasmen"}}

      assert property_ids == original_property_ids
      assert map_size(state.admins) == 1
    end

    test "using cache on second funtion call",
         ~M[state, admin, original_property_ids, changed_property_ids] do
      # When, fill cache
      {:reply, property_ids, state} =
        AccessServer.handle_call({:property_ids_for, admin}, __MODULE__, state)

      assert original_property_ids == property_ids
      assert map_size(state.admins) == 1

      # this will not be loaded because ids are already cached
      LoaderParrot.say_property_ids_for(changed_property_ids)

      # When, second call. use cache, not changed values
      {:reply, property_ids, state} =
        AccessServer.handle_call({:property_ids_for, admin}, __MODULE__, state)

      assert original_property_ids == property_ids
      assert map_size(state.admins) == 1

      assert_receive {:property_ids_for,
                      %AppCount.Core.ClientSchema{attrs: %{id: 23}, name: "dasmen"}}
    end

    test "handle_call(:clear, ...) ", ~M[original_property_ids] do
      state = %AccessServer{
        repo: LoaderParrot,
        admins: %{999 => original_property_ids}
      }

      # When clear
      {:reply, :ok, state} = AccessServer.handle_call(:clear, __MODULE__, state)
      assert map_size(state.admins) == 0
    end

    test "handle_info(:clear, ...) " do
      state = %AccessServer{admins: %{999 => [1, 2, 3, 4]}}

      # When clear
      {:noreply, state} = AccessServer.handle_info(:clear, state)
      assert map_size(state.admins) == 0
    end

    test "clears cache so adds changed_property_ids to cache on second function call",
         ~M[admin, original_property_ids, changed_property_ids] do
      state = %AccessServer{
        repo: LoaderParrot,
        admins: %{admin.id => original_property_ids}
      }

      assert map_size(state.admins) == 1

      # When clear
      {:reply, :ok, state} = AccessServer.handle_call(:clear, __MODULE__, state)
      assert map_size(state.admins) == 0

      # this will not be loaded because ids are already cached
      LoaderParrot.say_property_ids_for(changed_property_ids)

      # second call. use cache, not changed values
      {:reply, property_ids, state} =
        AccessServer.handle_call({:property_ids_for, admin}, __MODULE__, state)

      assert changed_property_ids == property_ids
      assert map_size(state.admins) == 1

      assert_receive {:property_ids_for,
                      %AppCount.Core.ClientSchema{attrs: %{id: 23}, name: "dasmen"}}
    end

    test "clears only admin_id from cache", ~M[state, admin] do
      # fill cache admin 01
      {:reply, _property_ids, state} =
        AccessServer.handle_call({:property_ids_for, admin}, __MODULE__, state)

      # fill cache admin02
      admin_02 = %{id: 84848}

      {:reply, _property_ids, state} =
        AccessServer.handle_call({:property_ids_for, admin_02}, __MODULE__, state)

      assert map_size(state.admins) == 2

      # When
      # {:clear, admin.id}
      {:reply, :ok, state} = AccessServer.handle_call({:clear, admin.id}, __MODULE__, state)
      assert map_size(state.admins) == 1
    end
  end

  describe "with DB" do
    setup do
      prop = insert(:property)
      prop2 = insert(:property)
      insert(:property)
      admin = admin_with_access([prop.id])
      ~M[admin: admin, property: prop, property_2: prop2]
    end

    test "property_ids_for", context do
      assert AccessServer.property_ids_for(context.admin) == [context.property.id]
    end

    test "filtered_property_ids_for", context do
      assert AccessServer.filtered_property_ids_for(context.admin, [context.property.id]) == [
               context.property.id
             ]

      assert AccessServer.filtered_property_ids_for(context.admin, [
               context.property.id,
               context.property_2.id
             ]) == [context.property.id]
    end
  end

  describe "has_permission?" do
    setup do
      prop = insert(:property)
      prop2 = insert(:property)
      insert(:property)
      admin = admin_with_access([prop.id])
      ~M[admin: admin, property: prop, property_2: prop2]
    end

    test " from regular admin", context do
      assert AccessServer.has_permission?(context.admin, context.property.id)
      new_prop = insert(:property)
      refute AccessServer.has_permission?(context.admin, new_prop.id)
    end

    test "from Super Admin" do
      new_prop = insert(:property)

      assert AccessServer.has_permission?(
               %{id: 789, roles: MapSet.new(["Super Admin"])},
               new_prop.id
             )
    end
  end
end
