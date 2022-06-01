defmodule AppCount.Leases.Utils.ParseScreening do
  import SweetXml

  def parse_gateway_xml(docs) do
    Enum.reduce(docs, %{criminal: [], credit: %{}}, &parse_doc/2)
  end

  def parse_doc(doc, data) do
    case xpath(doc, ~x"//CREDIT_SCORE") do
      nil -> Map.merge(data, %{criminal: data.criminal ++ parse_criminal(doc)})
      _ -> Map.merge(data, parse_credit(doc))
    end
  end

  def parse_credit(doc) do
    xmap(
      doc,
      credit: [
        ~x"//CREDIT_SCORE",
        value: ~x"./@_Value"S,
        type:
          ~x"./@_ModelNameType"S
          |> transform_by(&parse_model_name/1),
        date: ~x"./@_Date"S,
        factors: [
          ~x"./_FACTOR"l,
          code: ~x"./@_Code"S,
          text: ~x"./@_Text"S
        ]
      ]
    )
  end

  def parse_criminal(doc) do
    xmap(
      doc,
      records: [
        ~x"//Record"l,
        offenses: [
          ~x"./Offenses"l,
          offense: ~x"./Offense/Description/text()"S,
          date: ~x"./Offense/OffenseDate/text()"S
        ]
      ]
    )
    |> Map.get(:records)
  end

  def parse_model_name(name) do
    name
    |> String.replace(~r"([A-Z][a-z])", " \\1")
    |> String.replace(~r"([a-z])(\d)", "\\1 \\2")
  end
end
