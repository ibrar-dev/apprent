import React from "react";
import PageTitle from "../../../../components/atoms/pageTitle";
import getIsMobile from "../../../../components/atoms/utils/getIsMobile";
import AdvancedFiltersButton from "./advancedFiltersButton";
import {
  ActionButton,
  ExportButtons,
  BreakpointDisplay,
} from "../../../../components/atoms";

const isMobile = getIsMobile();
const newButtonTitle = isMobile ? "+ New" : "+ New Payment";

const TitleBar = ({
  count,
  csvData,
  csvFileName,
  filters,
  onChangeFilters,
  onNavigateToNewForm,
}) => (
  <div className="flex items-center justify-between px-4 md:px-10 xl:px-7">
    <PageTitle title="Payments" count={count}>
      {!isMobile && <i className="fas fa-money-check-alt mr-3" /> }
    </PageTitle>
    <div className="flex items-center">
      <BreakpointDisplay breakpoint={1520} under>
        <div className="flex items-center">
          <div className="mr-4">
            <AdvancedFiltersButton
              filters={filters}
              onChangeFilters={onChangeFilters}
            />
          </div>
          <ExportButtons csvData={csvData} csvFileName={csvFileName} />
        </div>
      </BreakpointDisplay>
      <ActionButton
        onClick={onNavigateToNewForm}
        title={newButtonTitle}
        big={!isMobile}
      />
    </div>
  </div>
);

export default TitleBar;
