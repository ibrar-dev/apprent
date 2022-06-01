import React from "react";
import tags from "./tags";

const links = {
  dashboard: {icon: "icon-speedometer", label: "Dashboard"},
  devices: {icon: "fas fa-tablet-alt", label: "Devices"},
  admins: {icon: "far fa-id-card", label: "Staff"},
  roles: {icon: "fas fa-user-tag", label: "Roles"},
  // features: {icon: "fas fa-th-list", label: "Features"},
  properties: {icon: "far fa-building", label: "Property Settings", tags: tags.property_settings},
  applications: {icon: "fab fa-wpforms", label: "Applications"},
  saved_forms: {icon: "fa fa-id-card", label: "Saved Applications"},
  tenants: {icon: "fas fa-users", label: "Residents"},
  units: {icon: "fas fa-cubes", label: "Units"},
  // openings: {icon: "icon-calendar", label: "Showing Hours"},
  prospects: {icon: "icon-call-in", label: "Prospects"},
  packages: {icon: "fas fa-truck", label: "Packages"},
  accounts: {icon: "fas fa-tasks", label: "Accounts"},
  payees: {icon: "fas fa-handshake", label: "Payees"},
  payments: {icon: "fas fa-money-bill-wave", label: "Payments"},
  orders: {icon: "fas fa-wrench", label: "Work Orders"},
  make_ready: {icon: "far fa-calendar-check", label: "Make Ready"},
  techs: {icon: "fas fa-robot", label: "Techs"},
  maintenance_reports: {icon: "fas fa-chart-area", label: "Analytics", tags: tags.maintenance_reports},
  vendors: {icon: "fas fa-user-tie", label: "Vendors"},
  maintenance_insight_reports: {icon: "fas fa-clipboard-list", label: "Insight Reports"},
  redemptions: {icon: "fas fa-medal", label: "Redemptions"},
  alerts: {icon: "fas fa-exclamation-circle", label: "Alerts"},
  system_settings: {icon: "fas fa-database", label: "System Settings", tags: tags.system_settings},
  // admin_actions: {icon: "fas fa-exclamation", label: "Admin Actions"},
  resident_events: {icon: `fas fa-${window.location.pathname === "/resident_events" ? "glass-cheers" : "wine-glass-alt"}`, label: "Events"},
  posts: {icon: `fas fa-${window.location.pathname === "/posts" ? "clipboard-list" : "clipboard"}`, label: "Social Posts"},
  mailings: {icon: `fas fa-${window.location.pathname === "/mailings" ? "envelope-open" : "envelope"}`, label: "Mailing Tool"},
  property_reports: {icon: `fas fa-${window.location.pathname === "/property_reports" ? "file-alt" : "file"}`, label: "Reports", tags: tags.property_reports},
  letters: {icon: `fas fa-file-${window.location.pathname === "/letters" ? "upload" : "download"}`, label: "Letters"},
  approvals: {icon: `fas fa-${window.location.pathname === "/approvals" ? "smile" : "thumbs-up"}`, label: "Approvals"},
  approvals_analytics: {icon: `fas fa-${window.location.pathname === "/approvals_analytics" ? "chart-bar" : "chart-pie"}`, label: "Approval Analytics"},
  "leases/renewals": {icon: `fas fa-${window.location.pathname === "leases/renewals" ? "file-signature" : "signature"}`, label: "Renewals"},
  // integrations: {icon: 'fas fa-charging-station', label: 'Integrations'},
  payments_analytics: {icon: `fas fa-${window.location.pathname === "/payments_analytics" ? "file-invoice-dollar" : "dollar-sign"}`, label: "Payment Analytics"}
};

const permissionsKey = {
  "Super Admin": Object.keys(links),
  Admin: [ "dashboard", "alerts", "payments",
    "reconcile", "approvals", "properties", "applications", "saved_forms",
    "tenants", "units", "packages", "leases/renewals", "accounting_reports",
    "prospects", "orders", "make_ready",
    "letters", "resident_events", "posts", "mailings",
    "property_reports", "budgets", "maintenance_insight_reports", "approvals_analytics", "redemptions", "payments_analytics"],
  Accountant: ["alerts", "reconcile", "accounts",
  "approvals", "charge_codes", "payees", "invoices", "checks", "payments", "payments_analytics",
    "report_templates", "journal_entries", "accounting_reports", "batches",
    "closings", "budgets", "maintenance_insight_reports", "approvals_analytics"],
  Agent: ["dashboard", "alerts", "applications", "tenants", "units", "packages",
    "prospects", "approvals", "payments", "payments_analytics", "maintenance_insight_reports", "approvals_analytics",
    "orders", "make_ready", "resident_events", "posts", "mailings", "letters", "redemptions"],
  Tech: ["dashboard", "alerts", "approvals", "orders", "make_ready", "techs",
    "maintenance_reports", "vendors", "budgets", "maintenance_insight_reports", "approvals_analytics"]
};

const groupings = {
  Dashboard: ["dashboard", "alerts"],
  System: ["system_settings", "devices", "admins", "roles"],
  Properties: ["properties" ],
  "Property Management": [ "applications", "saved_forms", "approvals", "approvals_analytics",
    "property_reports", "payments", "payments_analytics", "leases/renewals", "letters", "tenants",
    "units", "packages", "redemptions"],
  Social: [ "resident_events", "posts", "mailings" ],
  Prospects: ["prospects"],
  Accounts: ["accounts", "payees", "invoices",
  "checks", "payments", "payments_analytics", "budgets","report_templates", "journal_entries", "charge_codes",
  "accounting_reports", "batches", "closings", "reconcile"],
  Maintenance: ["orders", "make_ready", "maintenance_insight_reports", "materials", "techs",
    "maintenance_reports", "vendors"]
};

const roleTypes = Object.keys(permissionsKey);
const groupingList = Object.keys(groupings);

const data = (roles) => {
  const roleSet = new Set(roles);
  const linkSet = new Set();
  roleTypes.forEach(perm => {
    if (roleSet.has(perm)) permissionsKey[perm].forEach(link => linkSet.add(link));
  });
  const groups = {};
  groupingList.forEach(g => {
    groups[g] = groupings[g].filter(l => linkSet.has(l)).map(l => {
      return {...links[l], href: (l === "dashboard" ? "" : l)};
    });
  });
  return groups;
};

const permissions = (window.roles.some(r => r === "Super Admin")) ? Object.keys(permissionsKey) : window.roles;

export {permissions, data};
