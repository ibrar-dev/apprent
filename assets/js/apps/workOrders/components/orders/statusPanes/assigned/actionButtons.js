import React from "react";
import {Space, Button, Popconfirm} from "antd";
import {StopTwoTone} from "@ant-design/icons";
import {CreateOrderButton} from "../../renderers";
import PdfExport from "../../../../../../components/pdf";
import CsvExport from "../../exports/csv";

const exportColumns = ["Submitted", "Assigned", "Assigned to", "Location", "Resident", "Category", "View"];
const ActionButtons = ({
  onRevoke,
  length,
  newOrderDrawer,
  orders,
  dates,
  exportRows,
  exportFileName,
  csvData,
}) => (
  <div className="d-flex justify-content-between">
    <Space size="small">
      <Popconfirm
        title={`Really revoke ${length === 1 ? "this" : "these"}
        ${length} assignments?`}
        disabled={length < 1}
        onConfirm={onRevoke}
      >
        <Button icon={<StopTwoTone />} disabled={length < 1} type="link">Revoke</Button>
      </Popconfirm>
    </Space>
    <Space size="small">
      <CreateOrderButton newOrderDrawer={newOrderDrawer} />
      <PdfExport
        rows={exportRows(orders)}
        columns={exportColumns}
        fileName={exportFileName(dates)}
      />
      <CsvExport fileName={exportFileName(dates)} data={csvData(orders)} />
    </Space>
  </div>
);

export default ActionButtons;
