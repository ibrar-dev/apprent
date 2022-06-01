defmodule AppCount.Data.CacheRepoTest do
  use AppCount.DataCase
  alias AppCount.Data.CacheRepo
  @moduletag :cache_repo

  test "CacheRepo sets and gets arbitrary data" do
    data = {1, %{totally: "random"}, :piece, ["of", "some", "kind", "of"], "data"}
    CacheRepo.set("SOME_KEY", data)
    CacheRepo.set("SOME_OTHER_KEY", 123_456)
    assert CacheRepo.get("SOME_KEY") == data
    assert CacheRepo.get("SOME_OTHER_KEY") == 123_456
  end

  test "CacheRepo replaces existing data" do
    CacheRepo.set("SOME_KEY", 12345)
    CacheRepo.set("SOME_KEY", "let's do this")
    assert CacheRepo.get("SOME_KEY") == "let's do this"
  end

  test "CacheRepo clears existing data" do
    CacheRepo.set("SOME_KEY", 12345)
    CacheRepo.clear("SOME_KEY")
    assert CacheRepo.get("SOME_KEY") == nil
  end
end
