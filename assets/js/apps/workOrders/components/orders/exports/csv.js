import React from "react";
import {Button} from "antd";
import {CSVLink} from "react-csv";

const CsvExport = ({data, fileName}) => (
  <CSVLink data={data} filename={fileName}>
    <Button shape="circle" icon={<i className="fas fa-file-csv" />} />
  </CSVLink>
);

export default CsvExport;
