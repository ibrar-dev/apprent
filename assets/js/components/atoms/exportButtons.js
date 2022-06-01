import React from "react";
import styled from "styled-components";
import {CSVLink} from "react-csv";
import BreakpointDisplay from "./breakPointDisplay";
import {ExportAsExcelSvg} from "../icons";

const ExportButtons = ({csvData, csvFileName}) => (
  <div className="flex mr-3">
    <BreakpointDisplay breakpoint={768}>
      <div className="flex items-center">
        <BreakpointDisplay breakpoint={1024}>
          <ViewText>
            Export:
          </ViewText>
        </BreakpointDisplay>
        <div className="flex ml-2.5">
          {/* <ExportAsOtherSvg />
          <div className="mx-3">
            <PipeSvg />
          </div> */}
          <CSVLink
            filename={csvFileName}
            data={csvData}
          >
            <ExportAsExcelSvg />
          </CSVLink>
        </div>
      </div>
    </BreakpointDisplay>
  </div>
);

const ViewText = styled.div`
  font-weight: 600;
  font-size: 12px;
  white-space: nowrap;
  color: #04333B;
`;

export default ExportButtons;
