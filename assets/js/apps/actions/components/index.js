import React from 'react';
import {connect} from 'react-redux';
import Filters from './filters';
import Pagination from '../../../components/pagination';
import Action from "./action";

const headers = [
  {label: 'Date', sort: 'ts'},
  {label: 'Admin', sort: 'admin'},
  {label: 'IP', sort: 'ip'},
  {label: 'Description', sort: 'description'}
];

class ActionsApp extends React.Component {
  state = {};

  changeDates({startDate, endDate}) {
    startDate && startDate.startOf('day');
    endDate && endDate.endOf('day');
    this.setState({startDate, endDate})
  }

  changeFilter({target: {value}}) {
    this.setState({filter: value});
  }

  render() {
    const {actions} = this.props;
    return <>
      <Filters/>
      <Pagination title="Actions"
                  collection={actions}
                  component={Action}
                  headers={headers}
                  field="action"/>
    </>
  }
}

export default connect(({actions}) => {
  return {actions};
})(ActionsApp);
