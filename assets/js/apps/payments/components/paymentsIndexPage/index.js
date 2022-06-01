import React, {useState} from "react";
import {connect} from "react-redux";
import moment from "moment";
import {withRouter} from "react-router-dom";
import PageWrapper from "../../../../components/pageWrapper";
import actions from "../../actions";
import TitleBar from "./titleBar";
import FilterBar from "./filterBar";
import PaymentsTable from "./table";
import {filterList, initialFilter, buildCsv} from "./utils";
import {toCurr} from "../../../../utils";
import confirmation from "../../../../components/confirmationModal";
import canEdit from "../../../../components/canEdit";

const Payments = ({startDate, endDate, history}) => {
  // Initial Payments Fetching occurs in the PropertyFilter on render
  // via the onRefetchList callback function

  const [list, setList] = useState([]);
  const [filters, setFilters] = useState(initialFilter);
  const [pagination, setPagination] = useState({pageSize: 30, currentPage: 1});

  const onFetchList = () => actions.fetchBatches(setList);
  const filteredList = filterList(list, filters);
  const total = filteredList
    .reduce((acc, x) => acc + parseFloat(x.total) || 0, 0)
    .toFixed(2);

  const paginatedList = () => {
    const start = (pagination.currentPage - 1) * pagination.pageSize;
    const end = start + pagination.pageSize;
    return filteredList.splice(start, end);
  };

  const start = moment(startDate).format("MM/DD/YYYY");
  const end = moment(endDate).format("MM/DD/YYYY");
  const csvFileName = `Deposit Report ${start} - ${end}`;
  const isAbleToDelete = canEdit(["Super Admin", "Accountant", "Regional"]);

  const handleDeleteBatch = (id) => {
    if (isAbleToDelete) {
      confirmation("Delete this deposit?").then(() => {
        actions.deleteDeposit(id, setList);
      });
    }
  };

  const handleDeletePayment = (id) => {
    if (isAbleToDelete) {
      confirmation("Really delete this payment?").then(() => {
        actions.deletePayment(id, setList);
      });
    }
  };

  return (
    <PageWrapper>
      <TitleBar
        count={toCurr(total)}
        csvData={buildCsv(list)}
        csvFileName={csvFileName}
        filters={filters}
        onChangeFilters={setFilters}
        onNavigateToNewForm={() => history.push("/payments/new")}
      />
      <FilterBar
        // Triggers initial list fetch on render w/ PropertyFilter
        onRefetchList={onFetchList}
        onClearList={() => setList([])}
        dateFilter={[startDate, endDate]}
        onChangeDateFilter={(v) => actions.setDateFilters(v, onFetchList)}
        csvData={buildCsv(list)}
        csvFileName={csvFileName}
        filters={filters}
        onChangeFilters={setFilters}
      />
      <PaymentsTable
        totalItemsCount={filteredList.length}
        list={paginatedList()}
        pagination={pagination}
        onChangePage={(p) => setPagination({...pagination, currentPage: p})}
        onChangePageSize={(p) => setPagination({...pagination, pageSize: p})}
        onDeleteBatch={handleDeleteBatch}
        onDeletePayment={handleDeletePayment}
        isAbleToDelete={isAbleToDelete}
      />
    </PageWrapper>
  );
};

const mapStateToProps = ({dateFilters}) => {
  const {startDate, endDate} = dateFilters;
  return {startDate, endDate};
};
export default withRouter(connect(mapStateToProps, null)(Payments));
