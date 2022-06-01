defmodule AppCountWeb.BounceControllerTest do
  use ExUnit.Case, async: true
  use AppCountWeb.ConnCase
  @moduletag :bounce_controller

  defmodule BounceParrot do
    use TestParrot
    parrot(:bounce_repo_boundary, :create_from_ses, "session created")
  end

  setup do
    params =
      "{\n \"Type\" : \"Notification\",\n \"MessageId\" : \"8cb71acc-e9e3-5ec8-9b1c-42b34c7fef02\",\n \"TopicArn\" : \"arn:aws:sns:us-east-1:329390064905:apprent-handle-bounce\",\n \"Message\" : \"{\\\"notificationType\\\":\\\"Bounce\\\",\\\"bounce\\\":{\\\"feedbackId\\\":\\\"01000177160621f4-1d759d1b-7c1c-4864-a349-96e4ec9dbae8-000000\\\",\\\"bounceType\\\":\\\"Permanent\\\",\\\"bounceSubType\\\":\\\"General\\\",\\\"bouncedRecipients\\\":[{\\\"emailAddress\\\":\\\"perla11381@icloud.com\\\",\\\"action\\\":\\\"failed\\\",\\\"status\\\":\\\"5.1.1\\\",\\\"diagnosticCode\\\":\\\"smtp; 550 5.1.1 <perla11381@icloud.com>: user does not exist\\\"}],\\\"timestamp\\\":\\\"2021-01-18T15:03:56.000Z\\\",\\\"remoteMtaIp\\\":\\\"17.57.152.14\\\",\\\"reportingMTA\\\":\\\"dsn; a8-237.smtp-out.amazonses.com\\\"},\\\"mail\\\":{\\\"timestamp\\\":\\\"2021-01-18T15:03:54.323Z\\\",\\\"source\\\":\\\"admin@apprent.com\\\",\\\"sourceArn\\\":\\\"arn:aws:ses:us-east-1:329390064905:identity/admin@apprent.com\\\",\\\"sourceIp\\\":\\\"3.21.102.200\\\",\\\"sendingAccountId\\\":\\\"329390064905\\\",\\\"messageId\\\":\\\"01000177160618d3-b08bb011-41f7-4611-8661-e253a79e6118-000000\\\",\\\"destination\\\":[\\\"perla11381@icloud.com\\\"],\\\"headersTruncated\\\":false,\\\"headers\\\":[{\\\"name\\\":\\\"Received\\\",\\\"value\\\":\\\"from ip-10-1-32-195 (ec2-3-21-102-200.us-east-2.compute.amazonaws.com [3.21.102.200]) by email-smtp.amazonaws.com with SMTP (SimpleEmailService-d-HB9EV13A8) id mnFGIupHqFXn06eBUKQg for perla11381@icloud.com; Mon, 18 Jan 2021 15:03:54 +0000 (UTC)\\\"},{\\\"name\\\":\\\"Subject\\\",\\\"value\\\":\\\"[AppRent] Your service request, 7D722BAF9A has been assigned\\\"},{\\\"name\\\":\\\"From\\\",\\\"value\\\":\\\"AppRent Admin <admin@apprent.com>\\\"},{\\\"name\\\":\\\"To\\\",\\\"value\\\":\\\"perla11381@icloud.com\\\"},{\\\"name\\\":\\\"MIME-Version\\\",\\\"value\\\":\\\"1.0\\\"},{\\\"name\\\":\\\"Content-Type\\\",\\\"value\\\":\\\"multipart/mixed; boundary=\\\\\\\"----=_Part_3541128965_762600714.316386175\\\\\\\"\\\"}],\\\"commonHeaders\\\":{\\\"from\\\":[\\\"AppRent Admin <admin@apprent.com>\\\"],\\\"to\\\":[\\\"perla11381@icloud.com\\\"],\\\"subject\\\":\\\"[AppRent] Your service request, 7D722BAF9A has been assigned\\\"}}}\",\n \"Timestamp\" : \"2021-01-18T15:03:56.897Z\",\n \"SignatureVersion\" : \"1\",\n \"Signature\" : \"MTVd0nlPuaIZ/1UkqTPW6Zg7dddTSDzUgvox9ES8KIHRYBfTtpsulFd6GbSJ3lCAZP4FB9sieb8nHVeVzyHfh1nX221AmZTXxQIe5y4Cr+XUQOr5hCONVibznANG/1mxoY5qP4XnSt/LMR3YYAIvUpvL5cVz3QS9NqyM6ZlFssA7qyCcouJJ97zGojCA86sYwS+LNzo4abn/Y17lh9nD8E7pI3XTlJROUcY/R0zaoZYZ/+3DHkG+9OCkM9erWdQ/7bbxD9ggXHpJ4JCv7G9xX6jex+e3jtIR9uzHbJiiBOD1eJwwghrq0OuBvyslwRY9Pdv53Yfcaij1Wy6wGuX1hQ==\",\n \"SigningCertURL\" : \"https://sns.us-east-1.amazonaws.com/SimpleNotificationService-010a507c1833636cd94bdb98bd93083a.pem\",\n \"UnsubscribeURL\" : \"https://sns.us-east-1.amazonaws.com/?Action=Unsubscribe&SubscriptionArn=arn:aws:sns:us-east-1:329390064905:apprent-handle-bounce:80746221-a2d1-462a-953a-43c32efa7156\"\n}"

    ~M[params]
  end

  @tag subdomain: "administration"
  test "create handles and logs the text", ~M[conn, params] do
    conn =
      assign(conn, :bounce_repo_boundary, BounceParrot)
      |> put_req_header("content-type", "text/plain")

    # When
    conn = post(conn, Routes.bounce_path(conn, :create), params)

    assert_receive {:create_from_ses, ^params}
    assert json_response(conn, 200) == %{}
  end
end
