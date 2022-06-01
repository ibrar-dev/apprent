defmodule AppCountCom.Mailer.SenderTest do
  use AppCount.DataCase
  alias AppCountCom.Mailer.Sender
  alias AppCount.Messaging.BounceRepo

  defmodule RepoParrot do
    use TestParrot
    parrot(:repo, :exists?, false)
  end

  setup do
    valid = "someguy@test.com"
    ~M[valid]
  end

  test "can_send? to_address in a tuple", ~M[valid] do
    BounceRepo.insert(%{target: valid})
    can_send = Sender.can_send?({"", valid})

    assert !can_send
  end

  test "can_send? returns false when email is in DB", ~M[valid] do
    RepoParrot.say_exists?(true)
    can_send = Sender.can_send?(valid, RepoParrot)

    assert !can_send
  end

  test "can_send? returns true when email is not in DB", ~M[valid] do
    can_send = Sender.can_send?(valid, RepoParrot)

    assert can_send
  end
end
