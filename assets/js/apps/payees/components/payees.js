import React from 'react';
import {connect} from 'react-redux';
import {withRouter} from "react-router-dom";
import Pagination from '../../../components/pagination';
import Payee from './payee';
import PayeeForm from './payeeForm';

const headers = [
  {label: '', min: true},
  {label: 'Name', sort: 'name'},
  {label: 'Approved', min: true},
  {label: 'Invoices', min: true}
];

class Payees extends React.Component {
  state = {};

  _filters() {

  }

  render() {
    const {payees, payee, history} = this.props;
    if (payee) return <PayeeForm payee={payee}/>;
    const titleBar = <div>
      Payees
      <button className="btn btn-sm btn-success mt-0 mx-4" onClick={() => history.push("/payees/new")}>
        New Payee
      </button>
    </div>;
    return <Pagination title={titleBar}
                  collection={payees}
                  component={Payee}
                  headers={headers}
                  filters={this._filters()}
                  field="payee"
      />;
  }
}

export default withRouter(connect(({payees, payee}) => {
  return {payees, payee};
})(Payees));
