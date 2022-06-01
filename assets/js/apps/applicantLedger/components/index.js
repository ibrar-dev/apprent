import React from 'react';
import {connect} from 'react-redux';
import {Switch, Route} from "react-router-dom";
import Applicant from './applicant';
import actions from '../actions';

class ApplicationsApp extends React.Component {
  render() {
    const {transactions, applicants} = this.props;
    const fullTransactions = transactions.reduce((acc, p) => {
      if (!p.refund_date) return acc.concat([p]);
      const refund = {
        id: p.id,
        type: 'refund',
        payment: p,
        admin: p.edits.find(e => e.refund_date).admin,
        date: p.refund_date
      };
      return acc.concat([p, refund]);
    }, []).sort((a, b) => a.date > b.date ? 1 : -1);
    return <Switch>
      <Route exact path="/applicants/:id" render={(props) => {
        const id = parseInt(props.match.params.id);
        if (applicants.length === 0) {
          actions.fetchApplicant(id);
          return <div/>;
        }
        return <Applicant transactions={fullTransactions} applicants={applicants}/>;
      }}/>
    </Switch>;
  }
}

export default connect(({transactions, applicants}) => ({transactions, applicants}))(ApplicationsApp);