defmodule Yardi.Gateway.GetResidentDataCase do
  use AppCount.Case
  alias Yardi.Response.GetResidentData.Payment
  alias Yardi.Response.GetResidentData.Charge
  alias AppCount.Support.HTTPClient
  @moduletag :yardi_gateway_resident_data

  @get_resident_data File.read!(
                       Path.expand(
                         "../../resources/Yardi/get_resident_data.xml",
                         __DIR__
                       )
                     )

  @expected_result [
    %Payment{
      amount: "900.00",
      date: "2018-11-01",
      notes: ":Posted by QuickTrans",
      transaction_id: "600907748"
    },
    %Charge{
      amount: "900.00",
      code: "secdep",
      date: "2018-11-01",
      description: "Security Deposit Refundable",
      notes: ":Posted by QuickTrans (secdep)",
      transaction_id: "701429245"
    },
    %Charge{
      amount: "900.00",
      code: "rent",
      date: "2019-01-01",
      description: "Rent",
      notes: "Rent (01/2019)",
      transaction_id: "701475751"
    },
    %Payment{amount: "400.00", date: "2019-01-18", notes: nil, transaction_id: "600968322"},
    %Payment{amount: "500.00", date: "2019-01-18", notes: nil, transaction_id: "600968323"},
    %Charge{
      amount: "900.00",
      code: "rent",
      date: "2019-02-01",
      description: "Rent",
      notes: "Rent (02/2019)",
      transaction_id: "701536258"
    },
    %Charge{
      amount: "75.00",
      code: "late",
      date: "2019-02-06",
      description: "Late Fees",
      notes: "February Late Fee",
      transaction_id: "701588716"
    },
    %Charge{
      amount: "900.00",
      code: "rent",
      date: "2019-03-01",
      description: "Rent",
      notes: "Rent (03/2019)",
      transaction_id: "701685291"
    },
    %Payment{amount: "500.00", date: "2019-03-13", notes: nil, transaction_id: "601141606"},
    %Payment{amount: "400.00", date: "2019-03-13", notes: nil, transaction_id: "601141607"},
    %Charge{
      amount: "900.00",
      code: "rent",
      date: "2019-04-01",
      description: "Rent",
      notes: "Rent (04/2019)",
      transaction_id: "701930203"
    },
    %Payment{amount: "400.00", date: "2019-04-15", notes: nil, transaction_id: "601241098"},
    %Payment{amount: "500.00", date: "2019-04-15", notes: nil, transaction_id: "601241102"},
    %Charge{
      amount: "900.00",
      code: "rent",
      date: "2019-05-01",
      description: "Rent",
      notes: "Rent (05/2019)",
      transaction_id: "701936165"
    },
    %Charge{
      amount: "75.00",
      code: "late",
      date: "2019-05-06",
      description: "Late Fees",
      notes: "Late Fees Income",
      transaction_id: "701979065"
    },
    %Payment{amount: "500.00", date: "2019-05-21", notes: nil, transaction_id: "601274228"},
    %Payment{amount: "400.00", date: "2019-05-21", notes: nil, transaction_id: "601274229"},
    %Charge{
      amount: "900.00",
      code: "rent",
      date: "2019-06-01",
      description: "Rent",
      notes: "Rent (06/2019)",
      transaction_id: "701983996"
    },
    %Charge{
      amount: "75.00",
      code: "late",
      date: "2019-06-06",
      description: "Late Fees",
      notes: "Late Fees Income",
      transaction_id: "702095523"
    },
    %Charge{
      amount: "900.00",
      code: "rent",
      date: "2019-07-01",
      description: "Rent",
      notes: "Rent (07/2019)",
      transaction_id: "702141549"
    },
    %Charge{
      amount: "75.00",
      code: "late",
      date: "2019-07-07",
      description: "Late Fees",
      notes: "Late Fees Income",
      transaction_id: "702283461"
    },
    %Charge{
      amount: "50.00",
      code: "nsf",
      date: "2019-07-22",
      description: "NSF Fees Income",
      notes: "NSF Fees",
      transaction_id: "702294340"
    },
    %Payment{amount: "500.00", date: "2019-07-29", notes: nil, transaction_id: "601484878"},
    %Payment{amount: "500.00", date: "2019-07-29", notes: nil, transaction_id: "601484880"},
    %Charge{
      amount: "900.00",
      code: "rent",
      date: "2019-08-01",
      description: "Rent",
      notes: "Rent (08/2019)",
      transaction_id: "702269488"
    },
    %Charge{
      amount: "75.00",
      code: "late",
      date: "2019-08-06",
      description: "Late Fees",
      notes: "Late Fees Income",
      transaction_id: "702426726"
    },
    %Payment{amount: "500.00", date: "2019-08-19", notes: nil, transaction_id: "601585356"},
    %Payment{amount: "500.00", date: "2019-08-19", notes: nil, transaction_id: "601585370"},
    %Charge{
      amount: "200.00",
      code: "legal",
      date: "2019-08-19",
      description: "Legal Fees Income",
      notes: "Legal Fees Evicition Fees",
      transaction_id: "702426727"
    },
    %Charge{
      amount: "305.00",
      code: "legal",
      date: "2019-08-21",
      description: "Legal Fees Income",
      notes: "Legal Fees Evicition Fees",
      transaction_id: "702426728"
    },
    %Charge{
      amount: "900.00",
      code: "rent",
      date: "2019-09-01",
      description: "Rent",
      notes: "Rent (09/2019)",
      transaction_id: "702384871"
    },
    %Charge{
      amount: "189.00",
      code: "rent",
      date: "2019-09-01",
      description: "Rent",
      notes: "Rent",
      transaction_id: "702526874"
    },
    %Charge{
      amount: "250.00",
      code: "mtm",
      date: "2019-09-01",
      description: "Month to Month Fees",
      notes: "Month to Month Fees",
      transaction_id: "702526875"
    },
    %Charge{
      amount: "75.00",
      code: "late",
      date: "2019-09-06",
      description: "Late Fees",
      notes: "Late Fees Income",
      transaction_id: "702526882"
    },
    %Payment{amount: "500.00", date: "2019-09-16", notes: nil, transaction_id: "601629254"},
    %Payment{amount: "500.00", date: "2019-09-16", notes: nil, transaction_id: "601629255"},
    %Payment{amount: "500.00", date: "2019-09-16", notes: nil, transaction_id: "601629256"},
    %Charge{
      amount: "900.00",
      code: "rent",
      date: "2019-10-01",
      description: "Rent",
      notes: "Rent (10/2019)",
      transaction_id: "702524036"
    },
    %Charge{
      amount: "250.00",
      code: "mtm",
      date: "2019-10-01",
      description: "Month to Month Fees",
      notes: "Month to Month Fees",
      transaction_id: "702526876"
    },
    %Charge{
      amount: "189.00",
      code: "rent",
      date: "2019-10-01",
      description: "Rent",
      notes: "Rent",
      transaction_id: "702526878"
    },
    %Charge{
      amount: "-250.00",
      code: "mtm",
      date: "2019-10-01",
      description: "Month to Month Fees",
      notes: "Month to Month Fees",
      transaction_id: "702629875"
    },
    %Payment{amount: "500.00", date: "2019-10-02", notes: nil, transaction_id: "601709535"},
    %Payment{amount: "500.00", date: "2019-10-02", notes: nil, transaction_id: "601709536"},
    %Charge{
      amount: "-64.00",
      code: "rent",
      date: "2019-10-05",
      description: "Rent",
      notes: "Rent",
      transaction_id: "702629876"
    },
    %Charge{
      amount: "75.00",
      code: "late",
      date: "2019-10-10",
      description: "Late Fees",
      notes: "Late Fees Income",
      transaction_id: "702629878"
    },
    %Payment{amount: "500.00", date: "2019-10-16", notes: nil, transaction_id: "601711801"},
    %Payment{amount: "500.00", date: "2019-10-16", notes: nil, transaction_id: "601711802"},
    %Payment{amount: "500.00", date: "2019-10-18", notes: nil, transaction_id: "601711842"},
    %Charge{
      amount: "1025.00",
      code: "rent",
      date: "2019-11-01",
      description: "Rent",
      notes: "Rent (11/2019)",
      transaction_id: "702612384"
    },
    %Charge{
      amount: "75.00",
      code: "late",
      date: "2019-11-10",
      description: "Late Fees",
      notes: "Late Fees Income",
      transaction_id: "702629877"
    },
    %Payment{
      amount: "0.00",
      date: "2019-11-11",
      notes: ":Prog Gen credit application",
      transaction_id: "601720138"
    },
    %Payment{
      amount: "0.00",
      date: "2019-11-11",
      notes: ":Prog Gen credit application",
      transaction_id: "601720139"
    },
    %Charge{
      amount: "505.00",
      code: "legal",
      date: "2019-11-15",
      description: "Legal Fees Income",
      notes: "Legal Fees Evicition Fees",
      transaction_id: "702730751"
    },
    %Payment{amount: "500.00", date: "2019-11-26", notes: nil, transaction_id: "601740111"},
    %Payment{amount: "1000.00", date: "2019-11-26", notes: nil, transaction_id: "601740113"},
    %Charge{
      amount: "1025.00",
      code: "rent",
      date: "2019-12-01",
      description: "Rent",
      notes: "Rent (12/2019)",
      transaction_id: "702721641"
    },
    %Payment{amount: "500.00", date: "2019-12-03", notes: nil, transaction_id: "601792497"},
    %Charge{
      amount: "75.00",
      code: "late",
      date: "2019-12-06",
      description: "Late Fees",
      notes: "Late Fees Income",
      transaction_id: "702730658"
    },
    %Charge{
      amount: "1025.00",
      code: "rent",
      date: "2020-01-01",
      description: "Rent",
      notes: "Rent (01/2020)",
      transaction_id: "702809142"
    },
    %Payment{amount: "1000.00", date: "2020-01-02", notes: nil, transaction_id: "601864784"},
    %Payment{amount: "500.00", date: "2020-01-02", notes: nil, transaction_id: "601864794"},
    %Charge{
      amount: "75.00",
      code: "late",
      date: "2020-01-06",
      description: "Late Fees",
      notes: "Late Fees Income",
      transaction_id: "702849876"
    },
    %Charge{
      amount: "505.00",
      code: "legal",
      date: "2020-01-15",
      description: "Legal Fees Income",
      notes: "Legal Fees Evicition Fees",
      transaction_id: "702849991"
    },
    %Payment{
      amount: "927.00",
      date: "2020-01-21",
      notes: "NSFed by ctrl# 1897762 Account Closed",
      transaction_id: "601897761"
    },
    %Payment{
      amount: "463.50",
      date: "2020-01-23",
      notes: "NSFed by ctrl# 1897764 Account Closed",
      transaction_id: "601897763"
    },
    %Payment{
      amount: "-927.00",
      date: "2020-01-24",
      notes: "NSF receipt Ctrl# 1897761 Account Closed",
      transaction_id: "601897762"
    },
    %Charge{
      amount: "50.00",
      code: "nsf",
      date: "2020-01-24",
      description: "NSF Fees Income",
      notes: "Returned check charge",
      transaction_id: "702905289"
    },
    %Payment{amount: "200.00", date: "2020-01-28", notes: nil, transaction_id: "601886982"},
    %Payment{amount: "500.00", date: "2020-01-28", notes: nil, transaction_id: "601886984"},
    %Payment{
      amount: "-463.50",
      date: "2020-01-28",
      notes: "NSF receipt Ctrl# 1897763 Account Closed",
      transaction_id: "601897764"
    },
    %Charge{
      amount: "50.00",
      code: "nsf",
      date: "2020-01-28",
      description: "NSF Fees Income",
      notes: "Returned check charge",
      transaction_id: "702905290"
    },
    %Charge{
      amount: "1025.00",
      code: "rent",
      date: "2020-02-01",
      description: "Rent",
      notes: "Rent (02/2020)",
      transaction_id: "702902742"
    },
    %Payment{amount: "200.00", date: "2020-02-04", notes: nil, transaction_id: "601923961"},
    %Payment{amount: "500.00", date: "2020-02-04", notes: nil, transaction_id: "601923962"},
    %Charge{
      amount: "75.00",
      code: "late",
      date: "2020-02-06",
      description: "Late Fees",
      notes: "Late Fees Income",
      transaction_id: "702914021"
    },
    %Charge{
      amount: "1025.00",
      code: "rent",
      date: "2020-03-01",
      description: "Rent",
      notes: "Rent (03/2020)",
      transaction_id: "702995872"
    },
    %Payment{amount: "400.00", date: "2020-03-02", notes: nil, transaction_id: "601968536"},
    %Payment{amount: "500.00", date: "2020-03-02", notes: nil, transaction_id: "601968537"},
    %Payment{amount: "450.00", date: "2020-03-03", notes: nil, transaction_id: "601972986"},
    %Charge{
      amount: "75.00",
      code: "late",
      date: "2020-03-06",
      description: "Late Fees",
      notes: "Late Fees Income",
      transaction_id: "703002957"
    },
    %Payment{amount: "500.00", date: "2020-03-11", notes: nil, transaction_id: "601988957"},
    %Payment{amount: "500.00", date: "2020-03-18", notes: nil, transaction_id: "601995637"},
    %Payment{amount: "208.06", date: "2020-04-01", notes: nil, transaction_id: "602051025"},
    %Charge{
      amount: "1025.00",
      code: "rent",
      date: "2020-04-01",
      description: "Rent",
      notes: "Rent (04/2020)",
      transaction_id: "703099787"
    },
    %Charge{
      amount: "75.00",
      code: "late",
      date: "2020-04-06",
      description: "Late Fees",
      notes: "Late Fees Income",
      transaction_id: "703107088"
    },
    %Charge{
      amount: "-75.00",
      code: "late",
      date: "2020-04-09",
      description: "Late Fees",
      notes: "Late Fees Income",
      transaction_id: "703326198"
    },
    %Payment{amount: "333.46", date: "2020-04-13", notes: nil, transaction_id: "602071416"},
    %Payment{amount: "247.72", date: "2020-04-16", notes: nil, transaction_id: "602071433"},
    %Payment{amount: "183.86", date: "2020-04-24", notes: nil, transaction_id: "602084272"},
    %Charge{
      amount: "1025.00",
      code: "rent",
      date: "2020-05-01",
      description: "Rent",
      notes: "Rent (05/2020)",
      transaction_id: "703194098"
    },
    %Charge{
      amount: "75.00",
      code: "late",
      date: "2020-05-06",
      description: "Late Fees",
      notes: "Late Fees Income",
      transaction_id: "703196045"
    },
    %Charge{
      amount: "-75.00",
      code: "late",
      date: "2020-05-07",
      description: "Late Fees",
      notes: "Late Fees Income",
      transaction_id: "703326199"
    },
    %Payment{amount: "419.73", date: "2020-05-08", notes: nil, transaction_id: "602145170"},
    %Payment{amount: "311.83", date: "2020-05-14", notes: nil, transaction_id: "602148841"},
    %Payment{amount: "231.49", date: "2020-05-22", notes: nil, transaction_id: "602159843"},
    %Payment{amount: "171.75", date: "2020-05-22", notes: nil, transaction_id: "602159844"},
    %Charge{
      amount: "1025.00",
      code: "rent",
      date: "2020-06-01",
      description: "Rent",
      notes: "Rent (06/2020)",
      transaction_id: "703288772"
    },
    %Payment{amount: "391.66", date: "2020-06-05", notes: nil, transaction_id: "602219043"},
    %Payment{amount: "290.72", date: "2020-06-05", notes: nil, transaction_id: "602219044"},
    %Charge{
      amount: "75.00",
      code: "late",
      date: "2020-06-06",
      description: "Late Fees",
      notes: "Late Fees Income",
      transaction_id: "703294695"
    },
    %Charge{
      amount: "-75.00",
      code: "late",
      date: "2020-06-07",
      description: "Late Fees",
      notes: "Late Fees Income",
      transaction_id: "703326200"
    },
    %Payment{amount: "235.10", date: "2020-06-15", notes: nil, transaction_id: "602226117"},
    %Payment{
      amount: "0.00",
      date: "2020-06-19",
      notes: ":Prog Gen credit application",
      transaction_id: "602232441"
    },
    %Payment{
      amount: "0.00",
      date: "2020-06-19",
      notes: ":Prog Gen credit application",
      transaction_id: "602232442"
    },
    %Payment{
      amount: "0.00",
      date: "2020-06-19",
      notes: ":Prog Gen credit application",
      transaction_id: "602232443"
    },
    %Payment{amount: "55.23", date: "2020-06-19", notes: nil, transaction_id: "602233533"},
    %Payment{amount: "400.00", date: "2020-06-19", notes: nil, transaction_id: "602233588"},
    %Payment{
      amount: "0.00",
      date: "2020-07-01",
      notes: "Automatically generated apply prepay receipt.",
      transaction_id: "602270365"
    },
    %Charge{
      amount: "1025.00",
      code: "rent",
      date: "2020-07-01",
      description: "Rent",
      notes: "Rent (07/2020)",
      transaction_id: "703387368"
    },
    %Charge{
      amount: "75.00",
      code: "late",
      date: "2020-07-06",
      description: "Late Fees",
      notes: "Late Fees Income",
      transaction_id: "703394007"
    },
    %Payment{amount: "206.00", date: "2020-07-09", notes: nil, transaction_id: "602297856"},
    %Payment{amount: "515.00", date: "2020-07-17", notes: nil, transaction_id: "602309400"},
    %Payment{amount: "377.39", date: "2020-07-23", notes: nil, transaction_id: "602313300"},
    %Charge{
      amount: "1025.00",
      code: "rent",
      date: "2020-08-01",
      description: "Rent",
      notes: "Rent (08/2020)",
      transaction_id: "703486769"
    },
    %Payment{amount: "412.00", date: "2020-08-06", notes: nil, transaction_id: "602372881"},
    %Charge{
      amount: "75.00",
      code: "late",
      date: "2020-08-06",
      description: "Late Fees",
      notes: "Late Fees Income",
      transaction_id: "703495167"
    },
    %Payment{amount: "309.00", date: "2020-08-07", notes: nil, transaction_id: "602375953"},
    %Payment{amount: "185.40", date: "2020-08-17", notes: nil, transaction_id: "602385802"},
    %Payment{amount: "193.64", date: "2020-08-21", notes: nil, transaction_id: "602394717"},
    %Payment{
      amount: "0.00",
      date: "2020-08-31",
      notes: "Automatically generated apply prepay receipt.",
      transaction_id: "602414523"
    },
    %Payment{
      amount: "0.00",
      date: "2020-09-01",
      notes: ":Prog Gen prepayment transfer",
      transaction_id: "602415397"
    },
    %Charge{
      amount: "1050.00",
      code: "rent",
      date: "2020-09-01",
      description: "Rent",
      notes: "Rent (09/2020)",
      transaction_id: "703573334"
    },
    %Payment{amount: "515.00", date: "2020-09-04", notes: nil, transaction_id: "602448289"},
    %Charge{
      amount: "75.00",
      code: "late",
      date: "2020-09-06",
      description: "Late Fees",
      notes: "Late Fees Income",
      transaction_id: "703595960"
    },
    %Payment{amount: "309.00", date: "2020-09-11", notes: nil, transaction_id: "602455228"},
    %Payment{amount: "150.38", date: "2020-09-16", notes: nil, transaction_id: "602457895"},
    %Payment{amount: "150.38", date: "2020-09-18", notes: nil, transaction_id: "602462867"},
    %Charge{
      amount: "1050.00",
      code: "rent",
      date: "2020-10-01",
      description: "Rent",
      notes: "Rent (10/2020)",
      transaction_id: "703684718"
    },
    %Payment{amount: "402.73", date: "2020-10-02", notes: nil, transaction_id: "602525821"},
    %Charge{
      amount: "75.00",
      code: "late",
      date: "2020-10-07",
      description: "Late Fees",
      notes: "Late Fees Income",
      transaction_id: "703697234"
    },
    %Payment{amount: "517.00", date: "2020-10-15", notes: nil, transaction_id: "602528764"},
    %Payment{amount: "204.97", date: "2020-10-30", notes: nil, transaction_id: "602567547"},
    %Charge{
      amount: "1050.00",
      code: "rent",
      date: "2020-11-01",
      description: "Rent",
      notes: "Rent (11/2020)",
      transaction_id: "703781119"
    },
    %Charge{
      amount: "75.00",
      code: "late",
      date: "2020-11-06",
      description: "Late Fees",
      notes: "Late Fees Income",
      transaction_id: "703787938"
    },
    %Payment{
      amount: "100.00",
      date: "2020-11-18",
      notes: "AppRent Payment",
      transaction_id: "602601997"
    },
    %Payment{
      amount: "400.00",
      date: "2020-11-18",
      notes: "AppRent Payment",
      transaction_id: "602601998"
    },
    %Payment{
      amount: "400.00",
      date: "2020-11-25",
      notes: "AppRent Payment",
      transaction_id: "602609023"
    },
    %Payment{
      amount: "0.00",
      date: "2020-11-27",
      notes: ":Prog Gen credit application",
      transaction_id: "602610853"
    },
    %Payment{
      amount: "0.00",
      date: "2020-11-27",
      notes: ":Prog Gen credit application",
      transaction_id: "602610854"
    },
    %Payment{
      amount: "0.00",
      date: "2020-11-27",
      notes: ":Prog Gen credit application",
      transaction_id: "602610855"
    },
    %Charge{
      amount: "-225.00",
      code: "concoth",
      date: "2020-11-27",
      description: "Less: Other Concessions",
      notes: "Payment plan was kept we agreed to wave 3 late fees",
      transaction_id: "703819244"
    },
    %Payment{
      amount: "111.00",
      date: "2020-12-02",
      notes: "AppRent Payment",
      transaction_id: "602612560"
    },
    %Payment{
      amount: "0.00",
      date: "2020-12-04",
      notes: ":Prog Gen prepayment transfer",
      transaction_id: "602612561"
    }
  ]

  test "get_resident_data" do
    credentials = %{
      username: "",
      password: "",
      platform: "",
      server_name: "",
      db: "",
      url: "",
      entity: "",
      interface: "",
      gl_account: ""
    }

    HTTPClient.initialize([@get_resident_data])
    result = Yardi.Gateway.get_resident_data("1x1x", "t0017027", credentials)
    HTTPClient.stop()
    assert result == @expected_result
  end
end
