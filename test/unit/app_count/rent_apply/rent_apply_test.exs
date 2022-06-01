defmodule AppCount.RentApplyTest do
  use AppCount.DataCase
  import Mock
  import Ecto.Query
  use Bamboo.Test
  alias AppCount.RentApply.Forms
  # alias AppCount.Core.DomainEvent
  alias AppCount.Core.RentApplicationTopic

  @params %{
    "documents" => ["Driver's License", "Pay Stub"],
    "emergency_contacts" => [
      %{
        "address" => %{
          "address" => "14 Kenig",
          "city" => "Beitar",
          "state" => "CT",
          "unit" => "8",
          "zip" => "18940"
        },
        "email" => "nachman@elsner.com",
        "name" => "Nachman Elsner",
        "phone" => "(981) 234-5124",
        "relationship" => "Father in law"
      }
    ],
    "employments" => [
      %{
        "address" => %{
          "address" => "15 Tamarind",
          "city" => "Lakewood",
          "state" => "NJ",
          "unit" => "",
          "zip" => "18940"
        },
        "duration" => "2 years",
        "employer" => "Noket Enterprises",
        "occupant_index" => 1,
        "phone" => "(102) 398-4741",
        "email" => "mg@noket.com",
        "salary" => "10000",
        "supervisor" => "Miriam Gitlin "
      }
    ],
    "histories" => [
      %{
        "address" => %{
          "address" => "125 Springfield Rd",
          "city" => "Elizabeth ",
          "state" => "NJ",
          "unit" => "",
          "zip" => "18940"
        },
        "landlord_email" => "",
        "landlord_name" => "",
        "landlord_phone" => "",
        "current" => true,
        "rent" => false,
        "rental_amount" => 0,
        "residency_length" => "5 years"
      }
    ],
    "income" => %{
      "description" => "Embezzlement",
      "present" => true,
      "salary" => "5000"
    },
    "move_in" => %{
      "expected_move_in" => "2018-03-09",
      "unit_number" => ""
    },
    "occupants" => [
      %{
        "cell_phone" => "(653) 642-5316",
        "dl_number" => "123545",
        "dl_state" => "MH",
        "dob" => "1997-02-09",
        "email" => "somebody@gmail.com",
        "full_name" => "Some Body",
        "home_phone" => "(543) 212-5354",
        "ssn" => "333-22-1111",
        "status" => "Lease Holder",
        "work_phone" => "(625) 613-4556"
      },
      %{
        "cell_phone" => "(508) 123-7501",
        "dl_number" => "24130978",
        "dl_state" => "UT",
        "dob" => "1998-02-15",
        "email" => "mg3891@gmail.com",
        "full_name" => "Miriam Gitlin",
        "home_phone" => "(987) 152-1023",
        "ssn" => "111-22-3333",
        "status" => "Lease Holder",
        "work_phone" => "(409) 832-1750"
      }
    ],
    "pets" => [%{"breed" => "Husky", "name" => "Fred", "type" => "Dog", "weight" => "30"}],
    "vehicles" => []
  }

  @form_data %{
    "start_time" => 1_594_125_622,
    "language" => "English",
    "form_summary" => %{
      "documents" => %{"done" => true},
      "emergency_contacts" => %{"done" => true},
      "employments" => %{
        "collectionErrors" => [
          %{
            "address" => %{"zip" => "zip_error"},
            "supervisor" => "employment_super_error"
          }
        ]
      },
      "histories" => %{"done" => true},
      "income" => %{"done" => true},
      "move_in" => %{
        "errors" => %{"expected_move_in" => "movein_error"}
      },
      "occupants" => %{"done" => true},
      "pets" => %{"done" => true},
      "review" => %{},
      "vehicles" => %{"done" => true}
    }
  }

  setup do
    prop = insert(:property, setting: nil)
    insert(:setting, property: prop, instant_screen: true)
    payment = insert(:payment)
    insert(:processor, property: prop)
    {:ok, [property: prop, payment: payment]}
  end

  test "processes application and publish event", %{
    property: property,
    payment: payment
  } do
    RentApplicationTopic.subscribe()

    with_mock ExAws, request: fn _, _ -> {:ok, ""} end do
      data = File.read!(Path.expand("../../resources/Sample1.pdf", __DIR__))
      uuid = AppCount.UploadServer.initialize_upload(1, "Sample1.pdf", "application/pdf")
      AppCount.UploadServer.push_piece(uuid, data, 1)

      params =
        Map.merge(
          @params,
          %{
            "payment_id" => payment.id,
            "documents" => [
              %{
                "type" => "Driver's License",
                "url" => %{
                  "uuid" => uuid
                }
              }
            ]
          }
        )

      # When
      schema = AppCount.Core.ClientSchema.new("dasmen", %{property_id: property.id})
      {:ok, _result} = AppCount.RentApply.process_application(schema, params)

      # TODO turn on once it's connected
      #
      # application_id = result.application.id
      # assert_receive %DomainEvent{
      #   topic: "rent_apply__rent_applications",
      #   name: "created",
      #   content: %{items: _, account_id: _},
      #   subject_name: "AppCount.RentApply.RentApplication",
      #   subject_id: ^application_id,
      #   source: AppCount.RentApply.Utils.RentApplications
      # }
    end
  end

  test "processes application with null emergency contact address", %{
    property: property,
    payment: payment
  } do
    with_mock ExAws, request: fn _, _ -> {:ok, ""} end do
      data = File.read!(Path.expand("../../resources/Sample1.pdf", __DIR__))
      uuid = AppCount.UploadServer.initialize_upload(1, "Sample1.pdf", "application/pdf")
      AppCount.UploadServer.push_piece(uuid, data, 1)

      params =
        Map.merge(
          @params,
          %{
            "payment_id" => payment.id,
            "documents" => [
              %{
                "type" => "Driver's License",
                "url" => %{
                  "uuid" => uuid
                }
              }
            ]
          }
        )

      schema = AppCount.Core.ClientSchema.new("dasmen", %{property_id: property.id})
      assert {:ok, result} = AppCount.RentApply.process_application(schema, params)

      application = result.application
      application_id = application.id

      documents =
        Repo.all(
          from document in AppCount.RentApply.Document,
            where: document.application_id == ^application_id
        )

      assert length(documents) == 1

      fp = insert(:floor_plan, property: property, features: [insert(:feature, price: 900)])

      params =
        update_in(params["move_in"], &Map.put(&1, "floor_plan_id", fp.id))
        |> Map.put("documents", [])

      schema = AppCount.Core.ClientSchema.new("dasmen", %{property_id: property.id})
      {:ok, result} = AppCount.RentApply.process_application(schema, params)
      assert result

      unit = insert(:unit, property: property, floor_plan: fp)

      params =
        update_in(
          params["move_in"],
          &Map.merge(&1, %{"floor_plan_id" => nil, "unit_id" => unit.id})
        )
        |> Map.put("documents", [])

      schema = AppCount.Core.ClientSchema.new("dasmen", %{property_id: property.id})
      {:ok, result} = AppCount.RentApply.process_application(schema, params)
      assert result
    end
  end

  test "processes application works", %{property: property, payment: payment} do
    with_mock ExAws, request: fn _, _ -> {:ok, ""} end do
      data = File.read!(Path.expand("../../resources/Sample1.pdf", __DIR__))
      uuid = AppCount.UploadServer.initialize_upload(1, "Sample1.pdf", "application/pdf")
      AppCount.UploadServer.push_piece(uuid, data, 1)

      params =
        Map.merge(
          @params,
          %{
            "payment_id" => payment.id,
            "documents" => [
              %{
                "type" => "Driver's License",
                "url" => %{
                  "uuid" => uuid
                }
              }
            ]
          }
        )

      schema = AppCount.Core.ClientSchema.new("dasmen", %{property_id: property.id})
      {:ok, result} = AppCount.RentApply.process_application(schema, params)
      assert result

      fp = insert(:floor_plan, property: property, features: [insert(:feature, price: 900)])

      params =
        update_in(params["move_in"], &Map.put(&1, "floor_plan_id", fp.id))
        |> Map.put("documents", [])

      schema = AppCount.Core.ClientSchema.new("dasmen", %{property_id: property.id})
      {:ok, result} = AppCount.RentApply.process_application(schema, params)
      assert result

      unit = insert(:unit, property: property, floor_plan: fp)

      params =
        update_in(
          params["move_in"],
          &Map.merge(&1, %{"floor_plan_id" => nil, "unit_id" => unit.id})
        )
        |> Map.put("documents", [])

      schema = AppCount.Core.ClientSchema.new("dasmen", %{property_id: property.id})
      {:ok, result} = AppCount.RentApply.process_application(schema, params)
      assert result
    end
  end

  test "saved forms works", %{property: property} do
    Forms.create_saved_form(property.id, @params, @form_data)
    {:messages, messages} = Process.info(self(), :messages)

    emails =
      for {:delivered_email, _} = email_message <- messages do
        email_message
      end

    assert_email_delivered_with(
      subject: "[AppRent] Your Application Form PIN",
      html_body: ~r/and entering the following PIN number:/,
      to: [
        nil: "somebody@gmail.com"
      ]
    )

    tag =
      "<div style=\"font-family:Ubuntu, Helvetica, Arial, sans-serif;font-size:21px;font-weight:700;line-height:1;text-align:left;color:#000000;\">"

    pin_number =
      emails[:delivered_email].html_body
      |> String.splitter([tag])
      |> Enum.take(2)
      |> List.last()
      |> String.replace(~r/\s/, "")
      |> String.split("</div>")
      |> hd

    {:ok, %{form: form}} = Forms.get_decrypted_form(property.id, "somebody@gmail.com", pin_number)
    assert form == @params

    %{lang: lang, name: name, start_time: start_time, form_summary: form_summary} =
      Forms.get_saved_form(property.id, "somebody@gmail.com")

    assert lang == "English"
    assert name == "Some Body"

    assert start_time == DateTime.from_unix!(1_594_125_622)
    assert(form_summary == @form_data["form_summary"])

    assert {:error, :bad_auth} ==
             Forms.get_decrypted_form(property.id, "somebody@gmail.com", "RANDOM")
  end
end
