import React from 'react';
import {titleize} from "../../../utils";
import actions from "../actions";

class TrafficSource extends React.Component {
  deleteSource() {
    if (confirm('delete this traffic source?')) {
      actions.deleteTrafficSource(this.props.source);
    }
  }
  render() {
    const {source} = this.props;
    return <tr>
      <td>
        <a onClick={this.deleteSource.bind(this)}>
          <i className="fas fa-times text-danger"/>
        </a>
      </td>
      <td>
        {source.name}
      </td>
      <td>{source.type ? titleize(source.type) : " "}</td>
      <td>
        {source.num_prospects} Prospects
      </td>
    </tr>;
  }
}

export default TrafficSource;