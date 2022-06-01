import React from "react";
import styled from "styled-components";
import {Tooltip} from "antd";
import {InfoCircleOutlined} from "@ant-design/icons";
import moment from "moment";
import {Name, Title} from "./components";
import {toCurr} from "../../../../../utils";
import ActionsColumn from "./actionsColumn";

const capitalize = (word) => {
  if (!word) return "";
  const lower = word.toLowerCase();
  return word.charAt(0).toUpperCase() + lower.slice(1);
};

const calculatePaymentType = (paymentType, description) => {
  if (paymentType === "ba") return "Bank Account";
  if (paymentType === "cc") return "Credit Card";
  if (description === "Money Order") return "Money Order";
  if (description === "Check") return "Check";
  if (description === "MoneyGram Payment") return "MoneyGram";
  return "";
};

const BatchToolTipBody = ({
  id,
  inserted_at: insertedAt,
  payments,
  total,
}) => (
  <div>
    <div>
      Batch ID:
      {" "}
      {id}
    </div>
    <div>
      Deposit Date:
      {" "}
      {moment(insertedAt).format("MMMM DD, YYYY")}
    </div>
    <div>
      Post Month:
      {" "}
      {moment(payments[0].post_month).format("MM/YYYY")}
    </div>
    <div>
      Batch Total:
      {" "}
      {toCurr(total)}
    </div>
  </div>
);

const PaymentTableRow = ({
  onDeleteBatch,
  onDeletePayment,
  id: paymentId,
  inserted_at: insertedAt,
  tenant_name: tenantName,
  tenant_id: tenantId,
  post_error: postError,
  persons,
  unit,
  property_name: propertyName,
  source,
  description,
  payment_type: paymentType,
  payment_source_last_4: lastFour,
  amount,
  surcharge,
  status,
  transaction_id: transactionId,
  batch,
  isAbleToDelete,
}) => (
  <Tr style={{border: postError ? "4px solid red" : ""}}>
    <td>
      <div className="" style={{minWidth: 180}}>
        {
          postError && (
            <Name className="ml-1.5">
              <span style={{color: "red"}}>
                Post Error
                {" "}
              </span>
              <Tooltip title={postError}>
                <InfoCircleOutlined style={{color: "red", cursor: "pointer", verticalAlign: "0"}} />
              </Tooltip>
            </Name>
          )
        }
        {
          tenantId
            ? (<Name className="ml-1.5">{tenantName}</Name>)
            : (
              <>
                {
                  // Due to an unexpected issue there are several payments from applicants with no persons saved
                  // This happened from 06/21/21-06/22/1. It is not expected to happen again, but the page will crash if these payments are loaded in.
                  // We add this conditional to the map to make sure that persons exists when rendering. It will render an empty space, which is still better than a blank screen.
                  persons && persons.map(({full_name: fullName}) => (
                    <div key={fullName}>
                      <Name className="ml-1.5">{fullName}</Name>
                    </div>
                  ))
                }
              </>
            )
        }
        <Title>
          <span className="ml-1.5">
            {moment(insertedAt).format("MMMM DD, YYYY - h:mma")}
          </span>
        </Title>
      </div>
    </td>
    <td>
      <div style={{minWidth: 180}}>
        <div className="ml-2">
          <Name>{unit ? `Unit ${unit}` : ""}</Name>
          <Title>{propertyName}</Title>
        </div>
      </div>
    </td>
    <td>
      <div style={{minWidth: 180}}>
        <div className="ml-2">
          <Name>
            {transactionId}
          </Name>
          <Title>
            <span>
              Batch:
              {" "}
              {batch.id}
              {" "}
            </span>
            <Tooltip title={<BatchToolTipBody {...batch} />}>
              <InfoCircleOutlined style={{color: "green", cursor: "pointer", verticalAlign: "0"}} />
            </Tooltip>
          </Title>
          <Title>
            {capitalize(status)}
          </Title>
        </div>
      </div>
    </td>
    <td>
      <div style={{minWidth: 180}}>
        <div className="ml-2">
          <Name>
            {paymentType === "cc" && lastFour ? "**** **** **** " : null}
            {paymentType === "ba" && lastFour ? "******" : null}
            {lastFour}
          </Name>
          <Title>
            {calculatePaymentType(paymentType, description)}
          </Title>
        </div>
      </div>
    </td>
    <td>
      <div style={{minWidth: 180}}>
        <div className="ml-2">
          <Name>
            {toCurr(amount)}
          </Name>
          <Title>
            {toCurr(surcharge)}
          </Title>
        </div>
      </div>
    </td>
    <td>
      <div style={{minWidth: 180}}>
        <div className="ml-2">
          <Name>{description}</Name>
          <Title>{capitalize(source)}</Title>
        </div>
      </div>
    </td>
    <td>
      <div style={{minWidth: 180}}>
        <ActionsColumn
          paymentId={paymentId}
          onDeleteBatch={() => onDeleteBatch(batch.id)}
          onDeletePayment={() => onDeletePayment(paymentId)}
          isAbleToDelete={isAbleToDelete}
        />
      </div>
    </td>
  </Tr>
);

const Tr = styled.tr`
  border-bottom: 1px solid #E7EBEB;
  height: 80px;
`;

export default PaymentTableRow;
