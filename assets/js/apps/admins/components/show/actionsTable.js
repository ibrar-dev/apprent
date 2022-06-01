import React, {useState} from "react";
import {connect} from "react-redux";
import moment from "moment";
import {Input} from "reactstrap";
import Pagination from "../../../../components/pagination";
import DateRangePicker from "../../../../components/dateRangePicker";
import Action from "../../../actions/components/action";

const headers = [
  {label: "Date", sort: "ts"},
  {label: "Admin", sort: "admin"},
  {label: "IP", sort: "ip"},
  {label: "Description", sort: "description"},
];

const ActionsTable = ({actions}) => {
  const [startDate, setStartDate] = useState("");
  const [endDate, setEndDate] = useState("");
  const [filter, setFilter] = useState("");

  const changeDates = ({start, end}) => {
    setStartDate(start);
    setEndDate(end);
  };

  const filtered = () => actions.filter((a) => {
    if (startDate && endDate && !moment.unix(a.ts).isBetween(startDate, endDate)) return false;
    const regex = new RegExp(filter, "i");
    return regex.test(a.description) || regex.test(a.admin);
  });

  return (
    <Pagination
      title={(
        <DateRangePicker
          startDate={startDate}
          endDate={endDate}
          onDatesChange={changeDates}
        />
      )}
      collection={filtered()}
      component={Action}
      headers={headers}
      filters={(
        <Input
          value={filter || ""}
          onChange={(v) => setFilter(v.target.value)}
          placeholder="Admin or description"
        />
      )}
      field="action"
    />
  );
};

export default connect(({entities, activeAdmin, actions}) => (
  {entities, activeAdmin, actions}
))(ActionsTable);
