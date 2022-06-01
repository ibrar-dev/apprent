defmodule AppCount.Twilio.Messaging do
  defmodule Message do
    defstruct [
      :direction,
      :from_number,
      :to_number,
      :body,
      :external_id,
      :status,
      :extra_params,
      :media_types,
      :media_urls
    ]
  end

  def new_incoming(params) do
    %Message{
      direction: "incoming",
      from_number: params["From"],
      to_number: params["To"],
      body: String.trim(params["Body"]),
      external_id: params["SmsSid"],
      status: params["SmsStatus"],
      extra_params: params
    }
    |> Map.merge(media_params(params))
  end

  def new_outgoing(params) do
    %Message{
      direction: "outgoing",
      from_number: params.from,
      to_number: params.to,
      body: params.body,
      external_id: params.sid,
      status: params.status,
      extra_params: Map.from_struct(params)
    }
    |> Map.merge(media_params(params))
  end

  defp media_params(%{"NumMedia" => "0"}), do: %{}

  defp media_params(%{"NumMedia" => mms} = params) do
    num_of_media =
      String.to_integer(mms)
      |> Kernel.-(1)

    initial_acc = %{media_types: [], media_urls: []}

    0..num_of_media
    |> Enum.reduce(initial_acc, fn num, acc ->
      string = Integer.to_string(num)
      media_types = acc.media_types ++ [params["MediaContentType" <> string]]
      media_urls = acc.media_urls ++ [params["MediaUrl" <> string]]
      Map.merge(acc, %{media_types: media_types, media_urls: media_urls})
    end)
  end

  defp media_params(_), do: %{}
end
