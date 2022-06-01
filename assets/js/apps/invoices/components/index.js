import React from 'react';
import {connect} from 'react-redux';
import {Switch, Route, withRouter} from "react-router-dom";
import Invoices from './invoices';
import Invoice from './invoiceForm';

const initialInvoicings = () => [...new Array(5)].map((_, i) => {
  return {id: i + 1, amount_paid: 0, payments: [], validate: i <= 0}
});

class InvoicesApp extends React.Component {

  render() {
    const {invoices, history} = this.props;
    return <Switch>
      <Route exact path="/invoices/new"
             render={() => <Invoice invoice={{invoicings: initialInvoicings(), isNew: true}} history={history}/>}/>
      <Route exact path="/invoices/:id" render={(props) => {
        const invoice = invoices.find(i => i.id === parseInt(props.match.params.id));
        return invoice ? <Invoice invoice={invoice} history={history}/> : <div/>;
      }}/>
      <Route path="/invoices" component={Invoices}/>
    </Switch>;
  }
}

export default withRouter(connect(({invoices}) => {
  return {invoices};
})(InvoicesApp));
