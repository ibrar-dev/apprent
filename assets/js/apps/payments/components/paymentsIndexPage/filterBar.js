import React from "react";
import AdvancedFiltersButton from "./advancedFiltersButton";
import {
  ExportButtons,
  BreakpointDisplay,
  PropertyFilter,
  DateRangePicker,
} from "../../../../components/atoms";

const FilterBar = ({
  onRefetchList,
  onClearList,
  dateFilter,
  onChangeDateFilter,
  csvData,
  csvFileName,
  filters,
  onChangeFilters,
}) => (
  <div className="flex items-center md:mt-3 justify-between overflow-x-auto px-4 md:px-10 xl:px-7">
    <div className="flex pb-3 overflow-x-auto md:mb-0">
      <div className="mr-3">
        <PropertyFilter onPerformUpdate={onRefetchList} onClearList={onClearList} />
      </div>
      <div className="mr-3">
        <DateRangePicker
          dateFilter={dateFilter}
          onChangeDateFilter={onChangeDateFilter}
        />
      </div>
    </div>
    <BreakpointDisplay breakpoint={1520}>
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
  </div>
);
export default FilterBar;
