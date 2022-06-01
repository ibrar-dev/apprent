import React from "react";
import {connect} from 'react-redux';
import PageForm from "./pageForm";
import Pages from "./pages";
import moment from 'moment';
import {Switch, Route} from 'react-router-dom';

class JournalEntriesApp extends React.Component {

  render() {
    const {journalPages, history, editing} = this.props;
    return <Switch>
      <Route exact render={() =>
        <Pages journalPages={journalPages} history={history} editing={editing}/>} path="/journal_entries"/>
      <Route exact path="/journal_entries/:id" render={(props) => {
        const jPage = journalPages.find(i => i.id === parseInt(props.match.params.id));
        const page = {
          date: moment(),
          cash: true,
          accrual: true,
          entries: [{_id: 1}, {_id: 2}],
          ...jPage
        };
        return jPage ? <PageForm page={page} history={history}/> : <div/>;
      }}/>
    </Switch>
  }
}

export default connect(({journalPages, editing}) => {
  return {journalPages, editing};
})(JournalEntriesApp);