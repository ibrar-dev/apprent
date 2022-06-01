import React from "react";
import styled from "styled-components";
import PaymentRow from "./tableRow";
import device from "../../../../components/atoms/utils/device";
import Table from "../../../../components/atoms/table";

const PaymentsTable = ({
  list,
  pagination,
  onChangePage,
  onChangePageSize,
  totalItemsCount,
  onDeleteBatch,
  onDeletePayment,
  isAbleToDelete,
}) => {
  const headerRow = (
    <Tr>
      <th style={{minWidth: 180}}>
        <Header>
          Resident/Time
          <div className="ml-1.5">{/* {/* <SortArrowsSvg /> */}</div>
        </Header>
      </th>
      <th style={{minWidth: 180, textAlign: "left"}}>
        <Header>
          Unit/Property
          <div className="ml-1.5">{/* {/* <SortArrowsSvg /> */}</div>
        </Header>
      </th>
      <th style={{minWidth: 180, textAlign: "left"}}>
        <Header>
          Transaction ID/Status
          <div className="ml-1.5">{/* <SortArrowsSvg /> */}</div>
        </Header>
      </th>
      <th style={{minWidth: 180, textAlign: "left"}}>
        <Header>
          Payment Method
          <div className="ml-1.5">{/* <SortArrowsSvg /> */}</div>
        </Header>
      </th>
      <th style={{minWidth: 180, textAlign: "left"}}>
        <Header>
          Amount/Surcharge
          <div className="ml-1.5">{/* <SortArrowsSvg /> */}</div>
        </Header>
      </th>
      <th style={{minWidth: 180, textAlign: "left"}}>
        <Header>
          Description
          <div className="ml-1.5">{/* <SortArrowsSvg /> */}</div>
        </Header>
      </th>
      <th style={{minWidth: 180, textAlign: "left"}}>
        <Header>
          Actions
          <div className="ml-1.5">{/* <SortArrowsSvg /> */}</div>
        </Header>
      </th>
    </Tr>
  );

  const tableRows = (
    list.map((batch) => batch.payments.map((payment) => {
      const data = {...payment, batch};
      return (
        <PaymentRow
          key={`payment${payment.id}`}
          {...data}
          onDeleteBatch={onDeleteBatch}
          onDeletePayment={onDeletePayment}
          isAbleToDelete={isAbleToDelete}
        />
      );
    }))
  ).flat();

  return (
    <Table
      onChangePage={onChangePage}
      onChangePageSize={onChangePageSize}
      currentPage={0}
      itemsPerPage={15}
      headerRow={headerRow}
      tableRows={tableRows}
      pagination={pagination}
      totalItemsCount={totalItemsCount}
    />
  );
};

const Tr = styled.tr`
  border-bottom: 1px solid #E7EBEB;
  th {
    display: none;  
    @media ${device.tablet} {
      height: 40px;
      display:table-cell;
    }
  }
`;

const Header = styled.div`
  display: inline-flex;
  align-items: center;
  font-weight: 400;
  font-size: 12px;
  color: #9EACB0;
  cursor: pointer;
`;

export default PaymentsTable;
