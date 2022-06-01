defmodule Google.Maintenance do
  alias Google.Token
  require Logger

  @predict_url "https://automl.googleapis.com/v1/projects/1009897359707/locations/us-central1/models/TCN1156820372838940672:predict"
  @headers [{"Content-Type", "application/json"}]

  def get_cat_id_from_note(note) do
    token = Token.get_ml_token()

    headers =
      @headers
      |> Enum.concat([
        {"Authorization", "Bearer #{token}"}
      ])

    #    headers = {"Authorization: Bearer #{token}", "Content-Type: application/json"}
    data =
      note
      |> build_safe_note()
      |> build_payload()

    safe_post(data, headers, :single)
  end

  def get_cat_ids_from_note(note) do
    token = Token.get_ml_token()

    headers =
      @headers
      |> Enum.concat([
        {"Authorization", "Bearer #{token}"}
      ])

    #    headers = {"Authorization: Bearer #{token}", "Content-Type: application/json"}
    data =
      note
      |> build_safe_note()
      |> build_payload()

    safe_post(data, headers, :multi)
  end

  # TODO move this all into Port/Adapter Style with ExternalService
  def safe_post(data, headers, type, post_fn \\ &unsafe_post/4) do
    post_fn.(data, headers, type, HTTPoison)
  rescue
    ArgumentError ->
      Logger.error(
        "Google.Maintenance ArgumentError data: #{inspect(data, limit: :infinity)}, headers: #{
          inspect(headers)
        }",
        truncate: :infinity
      )

      :unable_to_get_id
  end

  def unsafe_post(data, headers, type, http_poison_module \\ HTTPoison) do
    http_poison_module.post(@predict_url, data, headers)
    |> case do
      {:ok, resp} -> handle_parse(resp, type)
      _ -> :unable_to_get_id
    end
  end

  def handle_parse(resp, :single), do: parse_id_from_resp(resp)

  def handle_parse(resp, :multi), do: parse_ids_from_resp(resp)

  # Build the data for the post request to get a maintenance__categories id
  def build_payload(note) do
    '{
      "payload" : {
          "textSnippet": {
               "content": "#{note}",
                "mime_type": "text/plain"
           },
        }
    }'
  end

  # Response returns a list of possible categories in most likely order. This parses and returns the first one in INT format
  def parse_id_from_resp(%{body: body} = _) do
    {:ok, list} = Poison.decode(body)

    List.first(list["payload"])["displayName"]
    |> String.to_integer()
  end

  def parse_ids_from_resp(%{body: body} = _) do
    {:ok, list} = Poison.decode(body)

    filtered =
      Enum.filter(list["payload"], fn cat ->
        cat["classification"]["score"] >= 0.01
      end)

    case length(filtered) do
      0 -> [List.first(list["payload"])]
      _ -> Enum.slice(filtered, 0, 5)
    end
  end

  def build_safe_note(note) do
    note
    |> remove_quotes()
    |> remove_backslash()
    |> remove_newline()
    |> remove_emoji()
  end

  def remove_backslash(note) do
    note
    |> String.replace("\\", "")
  end

  def remove_quotes(note) do
    note
    |> String.replace("\"", "")
  end

  def remove_newline(note) do
    note
    |> String.replace("\n", "")
  end

  def remove_emoji(note) do
    note
    |> String.to_charlist()
    |> Enum.filter(fn ch -> ch in 0..255 end)
    |> List.to_string()
  end
end
