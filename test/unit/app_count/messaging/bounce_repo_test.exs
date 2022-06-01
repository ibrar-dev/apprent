defmodule AppCount.Messaging.BounceRepoTest do
  use AppCount.DataCase
  alias AppCount.Messaging.BounceRepo
  @moduletag :bounce_test

  setup do
    builder =
      PropBuilder.new(:create)
      |> PropBuilder.add_admin()

    admin = PropBuilder.get_requirement(builder, :admin)

    valid = "someguy@test.com"
    invalid = "somerandomgibberish"

    ~M[valid, invalid, admin]
  end

  def aws_request() do
    "{\n  \"Type\" : \"Notification\",\n  \"MessageId\" : \"d9597d2e-accc-568f-b96e-gibberish\",\n  \"TopicArn\" : \"arn:aws:sns:us-east-1:329390064905:apprent-handle-bounce\",\n  \"Message\" : \"{\\\"notificationType\\\":\\\"Bounce\\\",\\\"bounce\\\":{\\\"feedbackId\\\":\\\"01000176b53c7d5a-bc922f00-cc06-464f-8367-gibberish-000000\\\",\\\"bounceType\\\":\\\"Permanent\\\",\\\"bounceSubType\\\":\\\"Suppressed\\\",\\\"bouncedRecipients\\\":[{\\\"emailAddress\\\":\\\"someguy@test.com\\\",\\\"action\\\":\\\"failed\\\",\\\"status\\\":\\\"5.1.1\\\",\\\"diagnosticCode\\\":\\\"Amazon SES has suppressed sending to this address because it has a recent history of bouncing as an invalid address. For more information about how to remove an address from the suppression list, see the Amazon SES Developer Guide: http://docs.aws.amazon.com/ses/latest/DeveloperGuide/remove-from-suppressionlist.html \\\"}],\\\"timestamp\\\":\\\"2020-12-30T20:00:09.000Z\\\",\\\"reportingMTA\\\":\\\"dns; amazonses.com\\\"},\\\"mail\\\":{\\\"timestamp\\\":\\\"2020-12-30T20:00:08.875Z\\\",\\\"source\\\":\\\"admin@apprent.com\\\",\\\"sourceArn\\\":\\\"arn:aws:ses:us-east-1:329390064905:identity/admin@apprent.com\\\",\\\"sourceIp\\\":\\\"11.111.11.111\\\",\\\"sendingAccountId\\\":\\\"111111111111\\\",\\\"messageId\\\":\\\"01000176b53c7cab-4c5f8539-8fae-444c-b49c-0e2c87c0045e-000000\\\",\\\"destination\\\":[\\\"eva@dasmenresidential.com\\\"],\\\"headersTruncated\\\":false,\\\"headers\\\":[{\\\"name\\\":\\\"Received\\\",\\\"value\\\":\\\"from ip-10-1-32-62 (ec2-18-218-61-103.us-east-2.compute.amazonaws.com [18.218.61.103]) by email-smtp.amazonaws.com with SMTP (SimpleEmailService-d-JZJFSQ2A8) id BcVMaEcoSxqHhgPwpW5I for someguy@test.com; Wed, 30 Dec 2020 20:00:08 +0000 (UTC)\\\"},{\\\"name\\\":\\\"Subject\\\",\\\"value\\\":\\\"[AppRent] New Email - Property One\\\"},{\\\"name\\\":\\\"From\\\",\\\"value\\\":\\\"AppRent Admin <admin@apprent.com>\\\"},{\\\"name\\\":\\\"To\\\",\\\"value\\\":\\\"someguy@test.com\\\"},{\\\"name\\\":\\\"MIME-Version\\\",\\\"value\\\":\\\"1.0\\\"},{\\\"name\\\":\\\"Content-Type\\\",\\\"value\\\":\\\"multipart/mixed; boundary=\\\\\\\"----=_Part_2572153107_4119841394.1144918174\\\\\\\"\\\"}],\\\"commonHeaders\\\":{\\\"from\\\":[\\\"AppRent Admin <admin@apprent.com>\\\"],\\\"to\\\":[\\\"someguy@test.com\\\"],\\\"subject\\\":\\\"[AppRent] New Application - Somerstone\\\"}}}\",\n  \"Timestamp\" : \"2020-12-30T20:00:09.313Z\",\n  \"SignatureVersion\" : \"1\",\n  \"Signature\" : \"F5tLgtekD5MCNuVSmqYKCngj33idwTSMnK/etiDMu9RefnqaoCDFLJD9PB2TYjnlbbzUaWcm9AQLyba57Lynj0W1YV2w5qizHQavFhz0/4sR++q8BcGFpgqmVxm8VsoFPW+nRlNTEkyOFWtRE06GwyViIa6tGqAWKupU2uY91zAF2Tf+DnIJx5eZ2KvmxmeaDkpzTlG16a1RiMQOS516yKVmBxYmI/xLVWgZBEG0MfHT1/nHoOz1V5drJA4h1LELk5ecX13DDFyxEUoerXnaVHjfKoomg//FqeJrDsqeGoPjVvT7ysVqKMFsccDxGDqWBr0RLNhnlOI+cuO3rHgc8w==\",\n  \"SigningCertURL\" : \"https://sns.us-east-1.amazonaws.com/SimpleNotificationService-010a507c1833636cd94bdb98bd93083a.pem\",\n  \"UnsubscribeURL\" : \"https://sns.us-east-1.amazonaws.com/?Action=Unsubscribe&SubscriptionArn=arn:aws:sns:us-east-1:329390064905:apprent-handle-bounce:80746221-a2d1-462a-953a-43c32efa7156\"\n}"
  end

  describe "exists?/1" do
    test "finds an existing email", ~M[valid] do
      params = %{target: valid}
      BounceRepo.insert(params)

      assert BounceRepo.exists?(valid)
    end

    test "does not find a non-existing email" do
      refute BounceRepo.exists?("not_in_zxczxcdb@example.com")
    end

    test "handles nil gracefully" do
      refute BounceRepo.exists?(nil)
    end

    test "finds case-insensitively", ~M[valid] do
      params = %{target: valid}
      BounceRepo.insert(params)

      new_valid = String.upcase(valid)
      assert BounceRepo.exists?(new_valid)
    end
  end

  test "count/0", ~M[valid] do
    params = %{target: valid}
    BounceRepo.insert(params)
    count = BounceRepo.count()

    assert count == 1
  end

  test "get_by/1", ~M[valid] do
    BounceRepo.insert(%{target: valid})
    found = BounceRepo.get_by(target: valid)

    assert found
  end

  test "create_from_ses creates records from SES SNS", ~M[valid] do
    aws_request = aws_request()
    BounceRepo.create_from_ses(aws_request)
    found = BounceRepo.get_by(target: valid)

    assert found
  end
end
