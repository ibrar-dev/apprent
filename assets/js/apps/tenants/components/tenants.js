import React, {useState} from "react";
import {connect} from "react-redux";
import {withRouter} from "react-router";
import moment from "moment";
import {CSVLink} from "react-csv";
import Pagination from "../../../components/pagination";
import TenantRow from "./tenantRow";
import AdvancedFilters from "./advancedFilters";
import actions from "../actions";
import {safeRegExp, capitalize} from "../../../utils";
import PropertySelect from "../../../components/propertySelect";
import tenantStatus from "../helpers/tenantStatus";

const loginSort = (r1, r2) => {
  const r1Login = r1.last_login ? new Date(r1.last_login) : null;
  const r2Login = r2.last_login ? new Date(r2.last_login) : null;
  return r1Login - r2Login;
};

const mapStatus = (status) => {
  if (status === "Current Lease") return 0;
  if (status === "Future") return 1;
  if (status === "Moved Out") return 2;
  if (status === "Evicted") return 3;
  if (status === "Under Eviction") return 4;
  if (status === "Renewal") return 5;
};

const statusSort = (r1, r2) => {
  const r1Status = tenantStatus(r1);
  const r2Status = tenantStatus(r2);
  return mapStatus(r1Status) - mapStatus(r2Status);
};

const sortByPresence = (key) => (
  (r1, r2) => {
    const r1Acct = r1[key] ? 1 : 0;
    const r2Acct = r2[key] ? 1 : 0;
    return r1Acct - r2Acct;
  }
);

const headers = [
  {label: "Name", sort: "name"},
  {label: "Email Status", sort: sortByPresence('bounce_id')},
  {label: "Unit", min: true, sort: "unit"},
  {label: "Status", sort: statusSort},
  {label: "Account Created", min: true, sort: sortByPresence('account_id')},
  {label: "AutoPay", min: true, sort: sortByPresence('autopay')},
  {label: "Last Login", sort: loginSort},
];

const testTenant = (filters, tenant) => {
  const fields = Object.keys(filters);
  if (fields.length < 1) return true;
  return Object.keys(filters).every((filter) => tenant[filter] === filters[filter]);
};

const Tenants = ({
  tenants, history, filters, property, properties, filter,
}) => {
  const [showAdvFiltersModal, setShowAdvFiltersModal] = useState(false);

  const toggleAdvFilter = () => setShowAdvFiltersModal(!showAdvFiltersModal);
  const filteredTenants = tenants.filter((t) => (
    safeRegExp(filter).test(t.name) && testTenant(filters, t)
  ));

  const csvData = () => {
    const rows = filteredTenants.map((t) => {
      return [
        t.name,
        t.bounce_id ? "invalid" : "",
        t.number,
        t.current_lease_status,
        t.account_id ? "yes" : "no",
        t.autopay ? "active" : "inactive",
        t.last_login ? moment.utc(t.last_login).local().format("MM/DD/YY hh:mm:A") : "N/A",
      ];
    });
    return [headers.map(({label}) => label), ...rows];
  };

  if (properties.length === 0) return <p>Loading</p>;
  return (
    <>
      <Pagination
        toggleIndex
        title={(
          <div className="d-flex align-items-center">
            <PropertySelect
              properties={properties}
              property={property}
              onChange={actions.setProperty}
            />
            <ul className="list-unstyled m-0 ml-2" style={{fontSize: "60%"}}>
              {
                Object.keys(filters).map((filter) => {
                  if (filter === "property") return null;
                  return (
                    <li
                      key={filter}
                      className="text-danger clickable"
                      onClick={actions.removeFilter.bind(null, filter)}
                    >
                      {capitalize(filter)} : {filters[filter]}
                    </li>
                  );
                })
              }
            </ul>
          </div>
        )}
        collection={filteredTenants}
        component={TenantRow}
        tableClasses="sticky-header table-sm"
        headers={headers}
        filters={(
          <input
            placeholder="Search By Tenant Name"
            className="form-control"
            value={filter}
            onChange={actions.changeFilter}
          />
        )}
        field="tenant"
        menu={[
          {title: "New Tenant", onClick: () => history.push("/tenants/new", {})},
          {title: "Advanced Filters", onClick: toggleAdvFilter},
          {title: "Download Mailing List", onClick: () => actions.get_mailing_list_csv(property.id)},
          {
            render: (id, index) => (
              <CSVLink
                className="btn btn-outline-info btn-spacing mt-0"
                filename={`Residents_${property.name}_${moment().format('MMMM DD, YYYY HH:mmA')}`}
                key={index}
                data={csvData()}
              >
                Download CSV
              </CSVLink>
            ),
          },
        ]}
      />
      {showAdvFiltersModal && <AdvancedFilters toggle={toggleAdvFilter} />}
    </>
  );
};

export default withRouter(connect(({
  tenants, filter, filters, properties, property,
}) => ({
  tenants, properties, property, filter, filters,
}))(Tenants));
