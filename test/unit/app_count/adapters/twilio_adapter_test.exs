defmodule AppCount.Adapters.TwilioAdapterTest do
  use AppCount.Case
  alias AppCount.Adapters.Twilio.Credential
  alias AppCount.Adapters.TwilioAdapter
  alias AppCount.Adapters.TwilioAdapterBehaviour.CreateMessageRequest
  alias AppCount.Adapters.TwilioAdapterBehaviour.CreateMessageResponse
  alias AppCount.Support.HTTPClient
  #  alias TwilioAdapter.Service
  import ExUnit.CaptureLog

  #  defp endpoint_url(port), do: "http://localhost:#{port}/"

  # TODO move somewhere
  def set_expectation(response, status_code) do
    {:ok, body} = Poison.encode(response)
    HTTPClient.add_http_response(body, status_code)
  end

  setup do
    on_exit(fn -> ExternalService.reset_fuse(TwilioAdapter.Service) end)
    message = "Hello World"
    phone_to = "+15005551111"
    phone_from = "+11234567890"

    expected_json = %{
      phone_from: phone_from,
      sid: "Some Sid",
      body: message
    }

    request =
      CreateMessageRequest.new(message: message, phone_to: phone_to, phone_from: phone_from)

    ~M[message, phone_to, request, expected_json, phone_from]
  end

  defp endpoint_url(), do: "http://localhost:/"

  describe "create_message_request" do
    test "phone_from per property", ~M[request] do
      # When
      message = TwilioAdapter.create_message_request(request)

      assert message =~ "Body=Hello+World"
      assert message =~ "To=%2B15005551111"
      assert message =~ "From=%2B11234567890"
    end

    test "default phone_from", ~M[request] do
      credentials = %{phone_from: "7778889999"}

      request = %{request | phone_from: nil}
      # When
      message = TwilioAdapter.create_message_request(request, credentials)

      assert message =~ "Body=Hello+World"
      assert message =~ "To=%2B15005551111"
      assert message =~ "From=%2B17778889999"
    end

    test "default phone_from is nil", ~M[request] do
      credentials = %{phone_from: nil}
      request = %{request | phone_from: nil}
      # When
      log_messages =
        capture_log(fn ->
          message = TwilioAdapter.create_message_request(request, credentials)
          assert message =~ "Body=Hello+World"
          assert message =~ "To=%2B15005551111"
          assert message =~ "From=Invalid+from_phone.+Check%3A+Twilio.Credential"
        end)

      assert log_messages =~
               "[error] Invalid Site Wide FROM Phone Number Check: Twilio.Credential"
    end

    test "default phone_from is short 444", ~M[request] do
      credentials = %{phone_from: "444"}
      request = %{request | phone_from: nil}
      # When
      log_messages =
        capture_log(fn ->
          message = TwilioAdapter.create_message_request(request, credentials)
          assert message =~ "Body=Hello+World"
          assert message =~ "To=%2B15005551111"
          assert message =~ "From=Invalid+from_phone.+Check%3A+Twilio.Credential"
        end)

      assert log_messages =~
               "[error] Invalid Site Wide FROM Phone Number Check: Twilio.Credential"
    end

    test "phone_from missing +1, automatically added", ~M[request] do
      request = %{request | phone_from: "1234567890"}
      # When
      message = TwilioAdapter.create_message_request(request)

      assert message =~ "Body=Hello+World"
      assert message =~ "From=%2B11234567890"
    end
  end

  describe "url" do
    test "sid is blank" do
      blank_sid = ""

      assert_raise(RuntimeError, "Twilio.Credential sid is blank", fn ->
        TwilioAdapter.compose_url(blank_sid, nil)
      end)
    end

    test "sid is nil" do
      nil_sid = nil

      assert_raise(RuntimeError, "Twilio.Credential sid is nil", fn ->
        TwilioAdapter.compose_url(nil_sid, nil)
      end)
    end

    test "with sid" do
      cred = Credential.load()

      url =
        cred.sid
        |> TwilioAdapter.compose_url(:not_set)

      assert url ==
               "https://api.twilio.com/2010-04-01/Accounts/ACb00a5b065ca8143b493adc85b6ac272b/Messages.json"
    end

    test "with injected url" do
      cred = Credential.load()

      url =
        cred.sid
        |> TwilioAdapter.compose_url("localhost:90")

      assert url == "localhost:90"
    end
  end

  describe "unsafe_remote_token using real API" do
    setup do
      HTTPClient.initialize([])
      on_exit(fn() -> HTTPClient.stop() end)
      {:ok, []}
    end

    test "success 201", ~M[request,  expected_json] do
      set_expectation(expected_json, 201)

      request_spec =
        TwilioAdapter.request_spec(
          request: request,
          url: endpoint_url(),
          verb: :post,
          returning: CreateMessageResponse
        )

      # When
      {:ok, create_message_response} = TwilioAdapter.unsafe_call(request_spec)

      assert %CreateMessageResponse{} = create_message_response

      assert create_message_response.sid
      refute create_message_response.error_code
      assert create_message_response.body == "Hello World"
    end

    test "Bad Request 400", ~M[request] do
      err_response = %{error: "Location must have a parent"}

      set_expectation(err_response, 400)
      request_spec = TwilioAdapter.request_spec(request: request, url: endpoint_url())

      log_messages =
        capture_log(fn ->
          # When
          result = TwilioAdapter.unsafe_call(request_spec)
          assert {:error, 400, "Bad Request"} = result
        end)

      assert log_messages =~
               "[error] Elixir.AppCount.Adapters.TwilioAdapter.decode_into() status_code: 400"

      assert log_messages =~ ~s[Location must have a parent]
      refute_receive %AppCount.Core.DomainEvent{}
    end

    test "cant call Anguilla(area code 264). Bad Request 400 code: 21211",
         ~M[request] do
      err_response = %{
        code: 21_211,
        message: "The 'To' number +12649877836 is not a valid phone number.",
        more_info: "https://www.twilio.com/docs/errors/21211"
      }

      set_expectation(err_response, 400)
      request_spec = TwilioAdapter.request_spec(request: request, url: endpoint_url())

      log_messages =
        capture_log(fn ->
          # When
          result = TwilioAdapter.unsafe_call(request_spec)
          assert {:error, 400, "Bad Request"} = result
        end)

      assert log_messages =~
               "[error] Elixir.AppCount.Adapters.TwilioAdapter.decode_into() status_code: 400"

      assert log_messages =~ ~s[The 'To' number +12649877836 is not a valid phone number]

      assert_receive %AppCount.Core.DomainEvent{
        content: %{phone: "+15005551111"},
        name: "invalid_phone_number",
        source: AppCount.Adapters.TwilioAdapter,
        topic: "sms"
      }
    end

    test "retry when a Server Error 500", ~M[request] do
      err_response = %{error: "An internal server error has occurred"}

      set_expectation(err_response, 500)
      request_spec = TwilioAdapter.request_spec(request: request, url: endpoint_url())

      log_messages =
        capture_log(fn ->
          # When
          result = TwilioAdapter.unsafe_call(request_spec)

          assert {:retry, "500-Internal Server Error"} = result
        end)

      assert log_messages =~
               "[error] Elixir.AppCount.Adapters.TwilioAdapter.decode_into() status_code: 500"

      assert log_messages =~ ~s[An internal server error has occurred]
    end

    test "Unauthorized - Bad Credentials 401 - bad credentials", ~M[request] do
      err_response = %{
        err: %{
          code: "invalid_token",
          inner: %{
            message: "jwt malformed",
            name: "JsonWebTokenError"
          },
          message: "jwt malformed",
          name: "UnauthorizedError",
          status: 401
        }
      }

      set_expectation(err_response, 401)

      request_spec = TwilioAdapter.request_spec(request: request, url: endpoint_url())

      log_messages =
        capture_log(fn ->
          # When
          result = TwilioAdapter.unsafe_call(request_spec)
          assert {:error, 401, "Unauthorized - Bad Credentials"} = result
        end)

      assert log_messages =~
               "[error] Elixir.AppCount.Adapters.TwilioAdapter.decode_into() status_code: 401"

      assert log_messages =~ ~s[UnauthorizedError]
      assert log_messages =~ ~s[invalid_token]
      assert log_messages =~ ~s[jwt malformed]
    end
  end

  describe "send_sms" do
    test "{:error, :fuse_blown", ~M[request] do
      expected_result = {:error, {:fuse_blown, Service}}

      unsafe_post_fn = fn _request -> expected_result end
      request_spec = TwilioAdapter.request_spec(request: request)

      # When
      result = TwilioAdapter.send_sms(request_spec, unsafe_post_fn)
      # Then
      assert result == expected_result
    end

    test "success for  ", ~M[request, expected_json] do
      unsafe_post_fn = fn _request -> CreateMessageResponse.new(expected_json) end

      request_spec = TwilioAdapter.request_spec(request: request)
      # When
      {:ok, create_message_response} = TwilioAdapter.send_sms(request_spec, unsafe_post_fn)

      # Then
      assert %CreateMessageResponse{} = create_message_response

      assert create_message_response.sid
      refute create_message_response.error_code
      assert create_message_response.body == "Hello World"
    end
  end

  # NOTES:
  # Working CURL command
  # curl -X POST https://api.twilio.com/2010-04-01/Accounts/ACb00a5b065ca8143b493adc85b6ac272b/Messages.json
  # --data-urlencode "Body=Hello World" --data-urlencode "From=+15005550006" --data-urlencode "To=+15005551111" -u ACb00a5b065ca8143b493adc85b6ac272b:5e026d4b7abf61162fe1a837e6d9d9bc
  # =>
  # {"sid": "SM460542e7ca9f43c0839c2d19fddfcecf", "date_created": "Tue, 11 Aug 2020 20:10:50 +0000", "date_updated": "Tue, 11 Aug 2020 20:10:50 +0000", "date_sent": null, "account_sid": "ACb00a5b065ca8143b493adc85b6ac272b", "to": "+15005551111", "from": "+15005550006", "messaging_service_sid": null, "body": "Hello World", "status": "queued", "num_segments": "1", "num_media": "0", "direction": "outbound-api", "api_version": "2010-04-01", "price": null, "price_unit": "USD", "error_code": null, "error_message": null, "uri": "/2010-04-01/Accounts/ACb00a5b065ca8143b493adc85b6ac272b/Messages/SM460542e7ca9f43c0839c2d19fddfcecf.json", "subresource_uris": {"media": "/2010-04-01/Accounts/ACb00a5b065ca8143b493adc85b6ac272b/Messages/SM460542e7ca9f43c0839c2d19fddfcecf/Media.json"}}
end
