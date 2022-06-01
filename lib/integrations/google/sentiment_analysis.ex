defmodule Google.SentimentAnalysis do
  @moduledoc """
  Use this to get the sentiment of any given string.
  Google returns a magnitute value and score for any passed in string.
  For details on how to interpret that visit: https://cloud.google.com/natural-language/docs/basics#interpreting_sentiment_analysis_values
  In short: the higher the magnitute the more emotion, positive scores are good emotions and negative scores are bad emotions.
  Our overlords at Google determine what is a good emtion and what is a bad emotion.
  """
  alias Google.Token

  @analysis_url "https://language.googleapis.com/v1/documents:analyzeSentiment"
  @headers [{"Content-Type", "application/json"}]

  def get_sentiment(string) do
    token = Token.get_ml_token()

    headers =
      @headers
      |> Enum.concat([
        {"Authorization", "Bearer #{token}"}
      ])

    build_payload(string)
    |> safe_post(headers)
  end

  def safe_post(data, headers, http_poison_module \\ HTTPoison) do
    http_poison_module.post(@analysis_url, data, headers)
    |> case do
      {:ok, resp} -> parse_resp(resp)
      _ -> :unable_to_get_sentiment
    end
  end

  # After parsing determine what to do with the analysis.
  def parse_resp(%{body: body}) do
    {:ok, parsed} = Poison.decode(body)

    parsed["documentSentiment"]
  end

  def build_payload(string) do
    string = String.replace(string, ~r/\p{So}/u, "")
    '{
      "encodingType": "UTF8",
      "document": {
        "type": "PLAIN_TEXT",
        "content": "#{string}"
      }
    }'
  end
end
