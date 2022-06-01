import React from 'react';
import {connect} from 'react-redux';
import Pagination from '../../../components/pagination';
import TrafficSource from './trafficSource';
import NewTrafficSource from "./newTrafficSource";

const headers = [
  {min: true},
  {label: "Name", sort: 'name'},
  {label: "Type", sort: 'type'},
  {label: "# Prospects", sort: 'num_prospects'}
];

class ProspectsApp extends React.Component {
  state = {};

  newSource() {
    this.setState({...this.state, newSource: !this.state.newSource});
  }

  render() {
    const {trafficSources} = this.props;
    const {newSource} = this.state;
    const title = <div>
      <button className="btn btn-success btn-sm m-0" onClick={this.newSource.bind(this)}>
        New Source
      </button>
    </div>;
    return <React.Fragment>
      <Pagination title={title}
                  collection={trafficSources}
                  component={TrafficSource}
                  headers={headers}
                  field="source"/>
      {newSource && <NewTrafficSource toggle={this.newSource.bind(this)}/>}
    </React.Fragment>;
  }
}

export default connect(({trafficSources}) => {
  return {trafficSources};
})(ProspectsApp);