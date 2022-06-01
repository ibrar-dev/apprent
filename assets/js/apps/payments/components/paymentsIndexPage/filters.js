import React from "react";
import {Input, Row} from "reactstrap";
import Check from "../../../../components/fancyCheck";

const CheckBox = ({
  label, name, onChange, checked,
}) => (
  <Row className="d-flex align-items-center ml-2">
    <Check
      onChange={onChange}
      checked={checked}
      name={name}
    />
    <label htmlFor="failed-payment-checkbox" className="ml-2 mt-2">
      {label}
    </label>
  </Row>
);

const FilterInput = ({
  value, name, onChange, label, placeholder,
}) => (
  <div className="labeled-box my-2">
    <Input
      value={value}
      name={name}
      onChange={onChange}
      placeholder={placeholder}
    />
    <div className="labeled-box-label">{label}</div>
  </div>
);

const Filters = ({filters, onChange, ref}) => {
  const changeFilter = ({target: {name, value}}) => {
    const newFilters = {...filters, [name]: value};
    onChange(newFilters);
  };

  const changeType = (field, {target: {checked}}) => {
    const newTypes = {...filters.types, [field]: checked};
    const newFilters = {...filters, types: newTypes};
    onChange(newFilters);
  };

  return (
    <>
      <FilterInput
        value={filters.resident || ""}
        name="resident"
        onChange={changeFilter}
        label="Resident"
      />
      <FilterInput
        value={filters.unit || ""}
        name="unit"
        onChange={changeFilter}
        label="Unit"
      />
      <FilterInput
        value={filters.checkId || ""}
        name="checkId"
        onChange={changeFilter}
        label="Transaction ID"
      />
      <FilterInput
        value={filters.last_4 || ""}
        name="last_4"
        onChange={changeFilter}
        label="Payment Method Last 4"
      />
      <div className="d-flex">
        <div className="labeled-box">
          <div className="labeled-box-label">Minimum Amount</div>
          <Input
            name="min"
            onChange={changeFilter}
            value={filters.min}
            type="number"
            style={{borderTopRightRadius: "0px", borderBottomRightRadius: "0px"}}
          />
        </div>
        <div className="labeled-box">
          <div className="labeled-box-label ">Maximum Amount</div>
          <Input
            name="max"
            onChange={changeFilter}
            value={filters.max}
            type="number"
            style={{borderTopLeftRadius: "0px", borderBottomLeftRadius: "0px"}}
          />
        </div>
      </div>

      {/* <FilterInput
        type="date"
        value={filters.batch_date || ""}
        name="batch_date"
        id="batch_date"
        onChange={changeFilter}
        label="Batch Date"
        placeholder="MM/DD/YYYY"
      />
      <FilterInput
        type="date"
        value={filters.post_month || ""}
        name="post_month"
        onChange={changeFilter}
        label="Post Month"
        placeholder="MM/YYYY"
      /> */}
      <hr className="my-2" />
      <CheckBox
        onChange={(e) => changeType("mo", e)}
        checked={filters.types.mo}
        name="money-order-checkbox"
        label="Money Order"
      />
      <CheckBox
        onChange={(e) => changeType("ch", e)}
        checked={filters.types.ch}
        name="check-checkbox"
        label="Check"
      />
      <CheckBox
        onChange={(e) => changeType("mngrm", e)}
        checked={filters.types.mngrm}
        name="moneygram-checkbox"
        label="MoneyGram"
      />
      <CheckBox
        onChange={(e) => changeType("appr", e)}
        checked={filters.types.appr}
        name="apprent-payment-checkbox"
        label="AppRent Payment"
      />
      <CheckBox
        onChange={(e) => changeType("appl", e)}
        checked={filters.types.appl}
        name="application-fee-checkbox"
        label="Application Fee"
      />
      <CheckBox
        onChange={(e) => changeType("admin", e)}
        checked={filters.types.admin}
        name="admin-fee-checkbox"
        label="Admin Fee"
      />
      <hr className="my-2" />
      <CheckBox
        onChange={(e) => changeType("successful_payments", e)}
        checked={filters.types.successful_payments}
        name="successful-payment-checkbox"
        label="Show Successful Payments"
      />
      <CheckBox
        label="Show Failed Payments"
        name="failed-payment-checkbox"
        onChange={(e) => changeType("failed_payments", e)}
        checked={filters.types.failed_payments}
      />
    </>
  );
};

export default Filters;
