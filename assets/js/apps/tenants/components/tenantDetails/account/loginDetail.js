import React, {useState} from "react";
import moment from "moment";
import {Button, Collapse} from "reactstrap"
import { capitalize } from "../../../../../utils";

const LoginDetail = ({timestamp, type, login_metadata}) => {
  const [detailsOpen, setDetailsOpen] = useState(false);
  const toggle = () => setDetailsOpen(!detailsOpen);

  const renderDetails = (data) => {
    if (Object.keys(data).length === 0) {
      return <p>No Additional Details</p>
    } else {
      const details = Object.entries(data).map(([key, value]) => <li key={key}><b>{key}:</b> {value}</li>)

      return (
        <ul>
          {details}
        </ul>
      );
    }
  }

  return (
    <div>
      <span>{moment(timestamp * 1000).format("MM/DD/YYYY HH:mmA")} - {capitalize(type)}</span>
      <Button color="link" onClick={toggle} >{detailsOpen ? "Hide Details" : "Details"}</Button>
      <Collapse isOpen={detailsOpen}>
        {renderDetails(login_metadata)}
      </Collapse>
    </div>
  );
}

export default LoginDetail;
