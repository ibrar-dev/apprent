defmodule AppCountWeb.Router do
  # @use_live_application System.get_env("APPRENT_LIVE_APPLICATION", "false")

  use AppCountWeb, :router
  import Phoenix.LiveDashboard.Router

  # Needs to be last in the list of use/import statements so we catch errors
  use Honeybadger.Plug

  web_module = Module.concat(["AppCountWeb"])
  api_1_module = Module.concat(["AppCountWeb.API.V1"])
  api_module = Module.concat(["AppCountWeb.API"])
  user_module = Module.concat(["AppCountWeb.Users"])
  layout_view = Module.concat(["AppCountWeb.LayoutView"])

  management = Module.concat(["AppCountWeb.Management"])

  if Mix.env() == :dev || System.get_env("APP_ENV") == "staging" do
    forward("/sent_emails", Bamboo.SentEmailViewerPlug)
  end

  pipeline :healthcheck do
    plug(:accepts, ["html"])
    plug(:fetch_session)
    plug(:fetch_live_flash)
    plug(:protect_from_forgery)
    plug(:put_secure_browser_headers)
    plug(:put_root_layout, {layout_view, :root})
  end

  pipeline :browser do
    plug(Plug.Logger)
    plug(:accepts, ["html"])
    plug(:fetch_session)
    plug(:fetch_live_flash)
    plug(:protect_from_forgery)
    plug(:put_secure_browser_headers)
    plug(AppCountWeb.BoundaryPlug)
    plug(:put_root_layout, {layout_view, :root})
    plug(AppCountWeb.RecordReferralPlug)
  end

  pipeline :public_api do
    plug(Plug.Logger)
    plug(:fetch_session)
    plug(AppCountWeb.BoundaryPlug)
    plug(:accepts, ["json", "xml", "text"])
  end

  pipeline :api_v1 do
    plug(Plug.Logger)
    plug(:accepts, ["json"])
    plug(:fetch_session)
    plug(AppCountWeb.AuthenticateAPIV1Plug)
    plug(AppCountWeb.RecordActionPlug)
    plug(AppCountWeb.BoundaryPlug)
  end

  pipeline :api do
    plug(Plug.Logger)
    plug(:accepts, ["json"])
    plug(:fetch_session)
    plug(AppCountWeb.AuthenticatePlug)
    plug(AppCountWeb.RecordActionPlug)
    plug(AppCountWeb.BoundaryPlug)
  end

  pipeline :tech_api do
    plug(Plug.Logger)
    plug(:accepts, ["json"])
    plug(:fetch_session)
    plug(AppCountWeb.AuthenticateTechPlug)
    plug(AppCountWeb.BoundaryPlug)
  end

  pipeline :protected do
    plug(Plug.Logger)
    plug(:accepts, ["html"])
    plug(:fetch_session)
    plug(:fetch_live_flash)
    plug(:protect_from_forgery)
    plug(:put_secure_browser_headers)
    plug(:put_root_layout, {layout_view, :root})
    plug(AppCountWeb.AuthenticatePlug)
    plug(AppCountWeb.RecordActionPlug)
    plug(AppCountWeb.BoundaryPlug)
  end

  pipeline :user_area do
    plug(Plug.Logger)
    plug(:accepts, ["html"])
    plug(:fetch_session)
    plug(:fetch_live_flash)
    plug(:protect_from_forgery)
    plug(:put_secure_browser_headers)
    plug(:put_root_layout, {layout_view, :root})
    plug(AppCountWeb.AuthenticateUserPlug)
    plug(AppCountWeb.AccomplishmentsPlug)
    plug(AppCountWeb.BoundaryPlug)
  end

  pipeline :user_api do
    plug(Plug.Logger)
    plug(:accepts, ["json"])
    plug(:fetch_session)
    plug(:fetch_live_flash)
    plug(AppCountWeb.BoundaryPlug)
    plug(AppCountWeb.AuthenticateUserPlug)
  end

  pipeline :resident_app_api do
    plug(Plug.Logger)
    plug(:accepts, ["json"])
    plug(AppCountWeb.BoundaryPlug)
    plug(AppCountWeb.AuthenticateAppPlug)
  end

  pipeline :management_web do
    plug(Plug.Logger)
    plug(:accepts, ["html"])
    plug(:fetch_session)
    plug(:fetch_live_flash)
    plug(:protect_from_forgery)
    plug(:put_secure_browser_headers)
    plug(:put_layout, {AppCountWeb.Management.LayoutView, :management})
    plug(AppCountWeb.ManagementPlug)
  end

  scope "/", management, host: "management." do
    pipe_through(:management_web)

    get("/", ClientController, :index)
    resources("/clients", ClientController)
    resources("/modules", ModuleController)
    resources("/actions", ActionController)
    delete("/sessions", SessionController, :delete)
  end

  scope "/", management, host: "management." do
    pipe_through(:browser)
    post("/sessions", SessionController, :create)
  end

  # scope "/", management do
  #   # pipe_through(:management)
  #   pipe_through(:management_web)
  #   get("/clients", ClientController, :index)
  # end

  # --- leasing
  scope "/api", api_module, host: "application." do
    pipe_through(:public_api)
    post("/uploads", UploadController, :create)
    patch("/uploads", UploadController, :update)
    get("/properties", PropertyListController, :index)
    resources("/forms", SavedFormController)
    post("/forms/get", SavedFormController, :show)
    post("/rent_applications", RentApplicationController, :create)
    get("/showings/:property_id", ShowingController, :new)
    post("/showings", ShowingController, :create)
  end

  scope "/", web_module, host: "application." do
    pipe_through(:browser)
    get("/new/:property_code", ApplicationFormController, :new)
    get("/payment/:crypt", ApplicationFormController, :index)
    #    get("/rent_applications/:signature", ApplicationFormController, :show)
    get("/showings/:property_code", ShowingController, :new)
    get("/:property_code", ApplicationFormController, :index)
  end

  scope "/", web_module, host: "maintenance." do
    pipe_through(:browser)
    live("/orders/rate", Live.Maintenance.OrdersLive.Rate)
    # live("/orders/:uuid", Live.Maintenance.OrdersLive.Show)
  end

  if Mix.env() == :test || Mix.env() == :dev do
    scope "/live", AppCountWeb.RentApp do
      pipe_through(:browser)
      live("/app/:property_code", ApplicationLive)
    end
  end

  scope "/", api_module, host: "residents." do
    pipe_through(:protected)
    get("/user_accounts/:id", UserAccountController, :show)
  end

  scope "/", web_module, host: "administration." do
    # resources("/clients", ClientController)
    pipe_through(:protected)
    get("/", DashboardController, :index)
    delete("/sessions", SessionController, :delete)

    scope "/regions" do
      live("/", Region.RegionLive, layout: {layout_view, "admin_root.html"})
    end

    get("/system_settings", SystemSettingsController, :index)

    # --- accounting
    get("/accounts", AccountController, :index)
    get("/bank_accounts", BankAccountController, :index)
    get("/charge_codes", ChargeCodeController, :index)
    get("/batches", BatchController, :index)
    get("/budgets", BudgetController, :index)
    get("/checks", CheckController, :index)
    get("/closings", ClosingController, :index)
    get("/features", FeatureController, :index)
    get("/invoices", InvoiceController, :index)
    get("/invoices/:id", InvoiceController, :index)
    get("/invoices/:id/doc", InvoiceController, :show)
    get("/journal_entries", JournalEntryController, :index)
    get("/journal_entries/:id", JournalEntryController, :index)
    get("/org_chart", OrgChartController, :index)
    get("/payees", PayeeController, :index)
    get("/payees/:id", PayeeController, :index)
    get("/payments", PaymentController, :index)
    get("/payments/:id", PaymentController, :index)
    get("/payments_analytics", PaymentAnalyticsController, :index)
    get("/report_templates", ReportTemplateController, :index)
    get("/reconcile", ReconciliationController, :index)
    get("/reconcile/:id", ReconciliationController, :index)
    get("/settings", SettingsController, :index)

    # --- leasing
    get("/applicants/:id", ApplicantController, :index)
    get("/applications", ApplicationController, :index)
    get("/applications/:id/lease", ApplicationController, :index)
    get("/applications/:id", ApplicationController, :index)
    get("/applications/:id/edit", ApplicationFormController, :edit)
    get("/openings", OpeningController, :index)
    get("/traffic_sources", TrafficSourceController, :index)
    get("/mailings", MailingController, :index)
    get("/application_leases/:id", ApplicationLeaseController, :show)
    get("/property_reports", PropertyReportController, :index)
    get("/leases", LeaseController, :index)
    get("/leases/reports", LeaseController, :index)
    get("/leases/renewals", LeaseController, :index)
    get("/leases/renewals/:id", LeaseController, :index)
    get("/leases/:id/new", LeaseController, :new)
    get("/leases/:id", LeaseController, :show)
    get("/saved_forms", SavedFormController, :index)
    get("/screenings/:id", ScreeningController, :show)

    # --- maintenance
    get("/categories", CategoryController, :index)
    get("/maintenance_clocks", TimecardController, :index)
    get("/maintenance_reports", MaintenanceReportController, :index)
    get("/make_ready", CardController, :index)
    get("/materials", StockController, :index)
    get("/materials/:id", StockController, :index)
    get("/materials/:id/report", StockController, :index)
    get("/materials/:id/shop", StockController, :index)
    get("/orders", OrderController, :index)
    get("/orders/:id", OrderController, :index)
    get("/prospects", ProspectController, :index)
    get("/stocks/:id/:action", StockController, :show)
    get("/techs", TechController, :index)
    get("/techs/:id", TechController, :index)
    get("/techs/maps", TechController, :index)
    get("/vendor_categories", VendorCategoryController, :index)
    get("/vendor_orders/:id", OrderController, :index)
    get("/vendors", VendorController, :index)
    get("/work_order_categories", WorkOrderCategoryController, :index)

    resources("/maintenance_insight_reports", MaintenanceInsightReportController,
      only: [:show, :index]
    )

    # --- packages
    get("/packages", PackageController, :index)
    get("/posts", PostController, :index)

    # --- rewards
    get("/rewards", RewardController, :index)
    get("/redemptions", PurchaseController, :index)

    live_dashboard("/super_protected_no_access_for_anyone_else_go_away_live_dashboard")
    get("/admins", AdminController, :index)
    get("/admins/:id", AdminController, :index)
    get("/admin_actions", ActionController, :index)
    get("/alerts", AlertController, :index)
    get("/approvals", ApprovalController, :index)
    get("/approvals/:id", ApprovalController, :index)
    get("/approvals_analytics", ApprovalAnalyticsController, :index)
    get("/devices", DeviceController, :index)
    get("/entities", EntityController, :index)
    get("/exports", ExportController, :index)
    get("/integrations", IntegrationController, :index)
    get("/jobs", JobController, :index)
    get("/letters", LetterController, :index)
    get("/migrations", MigrationController, :index)
    get("/properties", PropertyController, :index)
    get("/roles", RoleController, :index)
    get("/resident_events", ResidentEventController, :index)
    get("/tasks", TaskController, :index)
    get("/tenants", TenantController, :index)
    get("/tenants/:id", TenantController, :show)
    get("/units", UnitController, :index)
    get("/units/:id", UnitController, :index)
    get("/usage_dashboard", UsageDashboardController, :index)
    get("/user_accounts/:id", AdminUserSessionController, :show)
    get("/visits", VisitController, :index)
  end

  scope "/api", api_module, host: "administration.", as: "api" do
    pipe_through(:api)
    post("/uploads", UploadController, :create)
    patch("/uploads", UploadController, :update)
    get("/uploads/:uuid", UploadController, :show)
    post("/data", DataController, :create)
    resources("/org_chart", OrgChartController)
    resources("/roles", RoleController)

    # --- accounting
    resources("/accounting_charges", AccountingChargeController)
    resources("/property_admin_documents", PropertyAdminDocumentController)
    resources("/accounts", AccountController)
    resources("/account_categories", AccountCategoryController)
    resources("/bank_accounts", BankAccountController)
    resources("/banks", BankController)
    resources("/charge_codes", ChargeCodeController)
    resources("/credential_sets", CredentialSetController)
    resources("/reconcile", ReconciliationController)
    resources("/reconciliation_postings", ReconciliationPostingController)
    resources("/batches", BatchController)
    resources("/checks", CheckController)
    resources("/closings", ClosingController)
    resources("/damages", DamageController)
    resources("/documents", TenantDocumentController)
    resources("/evictions", EvictionController)
    resources("/features", FeatureController)
    resources("/floor_plans", FloorPlanController)
    resources("/finance_accounts", FinanceAccountController, only: [:create, :show, :index])
    resources("/invoice_payments", InvoicePaymentController)
    resources("/invoices", InvoiceController)
    resources("/invoicings", InvoicingController)
    resources("/journal_pages", JournalPageController)
    resources("/move_out_reasons", MoveOutReasonController)
    resources("/payees", PayeeController)
    resources("/payments", PaymentController)
    get("/payments_analytics", PaymentAnalyticsController, :index)
    resources("/registers", RegisterController)
    resources("/report_templates", ReportTemplateController)

    # --- maintenance
    resources("/assignments", AssignmentController)
    resources("/tech_recommend", TechRecommendController, only: [:index])
    resources("/card_items", CardItemController)
    resources("/cards", CardController)
    resources("/categories", CategoryController)
    resources("/maintenance_parts", MaintenancePartController)
    resources("/material_logs", MaterialLogController)
    resources("/material_types", MaterialTypeController)
    resources("/materials", MaterialController)
    resources("/notes", NoteController)
    resources("/vendor_notes", VendorNoteController)
    resources("/orders", OrderController)
    resources("/paid_times", PaidTimeController)
    resources("/recurring_orders", RecurringOrderController)
    resources("/stocks", StockController)
    resources("/techs", TechController)
    resources("/toolbox_items", ToolboxItemController)
    resources("/vendor_categories", VendorCategoryController)
    resources("/vendor_orders", VendorOrderController)
    resources("/vendors", VendorController)
    resources("/work_order_categories", WorkOrderCategoryController)
    post("/timecards", TimecardController, :index)
    post("/timecards/new", TimecardController, :create)
    patch("/timecards/:id", TimecardController, :update)
    get("/maintenance_reports", MaintenanceReportController, :index)
    post("/maintenance_reports", MaintenanceReportController, :create)
    post("/info_for_daily_report", MaintenanceReportController, :create)
    get("/info_for_daily_report", MaintenanceReportController, :index)
    get("/open_histories", OpenHistoriesController, :index)
    get("/external_ledgers/:external_id", ExternalLedgerController, :show)

    # -- leasing
    resources("/applicants", ApplicantController)
    resources("/applications", ApplicationController)
    resources("/application_leases", ApplicationLeaseController)
    resources("/closures", ClosureController)
    resources("/custom_packages", CustomPackageController)
    resources("/devices", DeviceController)
    resources("/default_lease_charges", DefaultLeaseChargesController)
    patch("/default_lease_charges", DefaultLeaseChargesController, :update)
    resources("/lease_forms", LeaseFormController)
    resources("/lease_renewals", LeaseRenewalController)
    resources("/lease_periods", LeasePeriodController)
    resources("/lease_reports", LeaseReportController)
    resources("/leases", LeaseController)
    resources("/letter_templates", LetterTemplateController)
    resources("/mailings", MailingController)
    resources("/mail_templates", MailTemplateController)
    resources("/property_templates", PropertyTemplateController)
    resources("/openings", OpeningController)
    resources("/occupants", OccupantController)
    resources("/recurring_letters", RecurringLetterController)
    resources("/rent_applications", RentApplicationController)
    resources("/prospects", ProspectController)
    get("/saved_forms", SavedFormAdminController, :index)
    resources("/screenings", ScreeningController)
    resources("/traffic_sources", TrafficSourceController)
    get("/rent_apply_documents/:id", RentApplyDocumentController, :show)
    post("/resident_emails", ResidentEmailController, :create)

    # --- rewards
    resources("/reward_purchases", RewardPurchaseController)
    resources("/reward_types", RewardTypeController)
    resources("/showings", ShowingController)
    resources("/prizes", RewardRESTController)
    resources("/rewards", TenantRewardsController)
    resources("/rewards_analytics", RewardsAnalyticsController)

    # --- packages
    resources("/packages", PackageController)

    resources("/admin_documents", AdminDocumentController)
    resources("/admin_actions", ActionController)
    resources("/admins", AdminController)

    resources("/insight_subscriptions", InsightReportSubscriptionsController,
      only: [:create, :index, :delete]
    )

    # --- text messages
    resources("/text_messages", TextMessageController)

    resources("/admin_profile", AdminProfileController)
    resources("/approvals", ApprovalsController)
    get("/approvals_analytics", ApprovalsAnalyticsController, :index)
    resources("/approvals_logs", ApprovalsLogsController)
    resources("/email_subscriptions", EmailSubscriptionsController)
    resources("/exports", ExportController)
    resources("/export_recipients", ExportRecipientController)
    resources("/entities", EntityController)
    resources("/integrations", IntegrationController)
    resources("/jobs", JobController)
    resources("/locks", LockController)
    resources("/migrations", MigrationController)
    resources("/pets", PetController)
    resources("/phone_lines", PhoneLineController)
    resources("/posts", PostController)
    resources("/properties", PropertyController)
    resources("/lease_charges", LeaseChargeController)
    resources("/resident_events", ResidentEventController)
    resources("/regions", RegionController)
    resources("/resident_event_attendances", ResidentEventAttendanceController)
    resources("/tasks", TaskController)
    resources("/tenancies", TenancyController)

    resources("/tenants", TenantController) do
      post("/clear_bounces", TenantController, :clear_bounces)
    end

    resources("/units", UnitController)
    resources("/vehicles", VehicleController)
    resources("/visits", VisitController)
    resources("/user_accounts", UserAccountController)
    resources("/user_stats", UserStatController)
    get("/agents", AgentController, :index)
    get("/approval_costs/:id", ApprovalCostsController, :show)
    get("/approval_costs", ApprovalCostsController, :index)
    get("/events", EventController, :index)
    get("/calculations", CalculationController, :index)
    get("/property_report", PropertyReportController, :index)
    get("/property_meta/", PropertyMetaController, :index)
  end

  scope "/sessions", web_module, host: "administration." do
    pipe_through(:browser)
    post("/", SessionController, :create)
  end

  scope "/forgot_password", web_module, host: "administration." do
    pipe_through(:browser)
    get("/", PasswordController, :index)
    post("/", PasswordController, :create)
    patch("/", PasswordController, :update)
  end

  scope "/remote_approvals", web_module, host: "administration." do
    pipe_through(:browser)
    get("/:token/:status", RemoteApprovalsController, :index)
  end

  scope "/", web_module, host: "administration." do
    pipe_through(:public_api)
    post("/tenant_safe", TenantSafeController, :update)
    post("/money_gram", MoneyGramController, :create)
    post("/bounce", BounceController, :create)
  end

  scope "/app", api_module, host: "administration." do
    pipe_through(:public_api)
    post("/sessions", SessionController, :create)
    delete("/sessions", SessionController, :delete)
  end

  scope "/", web_module, host: "residents." do
    pipe_through(:browser)
    get("/user_accounts/:id/:token", AdminUserSessionController, :create)
  end

  scope "/", api_module do
    pipe_through(:public_api)
    get("/rent_applications", RentApplicationController, :index)
    post("/signature", SignaturesController, :show)
    post("/tech_branding", TechAuthController, :create)
    post("/emails", EmailController, :create)
  end

  scope "/api", api_module, host: "appwork." do
    pipe_through(:tech_api)
    post("/uploads", UploadController, :create)
    patch("/uploads", UploadController, :update)
  end

  scope "/sessions", web_module do
    pipe_through(:healthcheck)
    get("/", SessionController, :new)
  end

  scope "/", user_module, as: :user do
    pipe_through(:user_area)

    # ---  accounting
    get("/", DashboardController, :index)

    # --- maintenance
    resources("/work_orders", OrderController)

    # --- packages
    get("/packages", PackageController, :index)

    resources "/assignments", AssignmentController, only: [:update] do
      get("/edit_rating", AssignmentController, :edit_rating)
    end

    # ---  accounting
    get("/documents", DocumentController, :index)

    resources "/payment_sources", PaymentSourceController,
      only: [:index, :edit, :delete, :update],
      as: :ps do
      post("/make_default/", PaymentSourceController, :make_default)
    end

    get("/payments", PaymentController, :index)
    get("/payment", PaymentController, :index)
    get("/profile", AccountController, :index)

    get("/dashboard", DashboardController, :index)
    get("/property", PropertyController, :index)

    # ---  rewards
    get("/rewards", RewardController, :index)

    resources("/social", SocialController)
  end

  scope "/api/v1", AppCountWeb.Users.API.V1, as: :user do
    pipe_through(:resident_app_api)
    resources("/autopay", AutoPayController)
    delete("/mailings/:id", MailingController, :delete)
    get("/events", EventController, :index)
    get("/mailings", MailingController, :index)
    get("/packages", PackagesController, :index)
    get("/profile", AccountController, :index)
    get("/property", PropertyController, :index)
    get("/work_order_categories", OrderCategoryController, :index)
    get("/tokenization_credentials", PaymentSourceController, :tokenization_credentials)
    patch("/profile", AccountController, :update)

    resources "/payment_sources", PaymentSourceController,
      only: [:create, :index, :update, :delete] do
      post("/make_default", PaymentSourceController, :make_default)
    end

    resources("/payments", PaymentController, only: [:index, :create], as: :api_v1_payment)
    resources("/posts", PostController)
    resources("/renewals", RenewalController)
    resources("/work_orders", OrderController)

    # ---  rewards
    resources("/rewards", RewardController, only: [:index, :create])
  end

  scope "/api/v2", AppCountWeb.Users.API.V2, as: :api_v2 do
    pipe_through(:resident_app_api)
    resources("/payments", PaymentController, only: [:create])
  end

  scope "/", user_module, as: :user do
    pipe_through(:user_api)

    # --- accounting
    post("/payment_sources", PaymentSourceController, :create)
    post("/payments", PaymentController, :create, as: :resident_payment)

    # ---  rewards
    post("/rewards", RewardController, :create)

    patch("/profile", AccountController, :update)
  end

  # --- :accounting, :maintenance
  scope "/", user_module, as: :user do
    pipe_through(:browser)
    get("/about", StaticPageController, :about)
    get("/contact", StaticPageController, :contact)
    get("/forgot-password", PasswordController, :index)
    post("/forgot-password", PasswordController, :create)
    patch("/forgot-password", PasswordController, :update)
    get("/login", SessionController, :index)
    post("/login", SessionController, :create)
    delete("/logout", SessionController, :delete)
    get("/privacy", StaticPageController, :privacy)
  end

  scope "/", user_module, as: :user do
    pipe_through(:public_api)
    get("/api/v1/check_email", API.V1.SessionController, :show)
    post("/api/v1/profile", API.V1.AccountController, :create)
    post("/api/v1/login", API.V1.SessionController, :create)
    post("/contact", StaticPageController, :ticket)
    get("/accept", StaticPageController, :accept)
  end

  # Public namespaced controllers, such as Twilio handling replies
  # SPA Re-Design Public Routes
  scope "/api/v1", api_1_module, host: "administration.", as: "admin_api_v1" do
    pipe_through(:public_api)
    post("/sessions", SessionController, :create)
    post("/twilio", TwilioController, :create)
  end

  # SPA Re-Design Routes
  scope "/api/v1", api_1_module, host: "administration.", as: "admin_api_v1" do
    pipe_through(:api_v1)
    resources("/categories", CategoryController, only: [:index])
    resources("/techs", TechController, only: [:index, :show, :update])
  end
end
