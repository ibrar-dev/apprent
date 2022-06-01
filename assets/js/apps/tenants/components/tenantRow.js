import React from "react";
import moment from "moment";
import {withRouter} from "react-router";
import tenantStatus from "../helpers/tenantStatus";

const TenantRow = ({tenant, history}) => {
  return (
    <tr onClick={() => history.push(`/tenants/${tenant.id}`, {})} className="link-row">
      <td className={tenant.current_haprent ? "text-warning" : ""}>
        {tenant.name}
      </td>
      <td>
        {tenant.bounce_id && <span className="badge bg-danger text-light">Invalid Email</span>}
      </td>
      <td className="text-right">
        {tenant && `${tenant.unit}`}
      </td>
      <td>
        {tenantStatus(tenant)}
      </td>
      <td>
        <i className={`fas fa-${tenant.account_id ? "check text-success" : "times text-danger"}`} />
      </td>
      <td>
        <i className={`fas fa-${tenant.autopay ? "check text-success" : "times text-danger"}`} />
      </td>
      <td>
        {tenant.last_login ? moment.utc(tenant.last_login).local().format("MM/DD/YY hh:mm:A") : "N/A"}
      </td>
    </tr>
  );
};

export default withRouter(TenantRow);
