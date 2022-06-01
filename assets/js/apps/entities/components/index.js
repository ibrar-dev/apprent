import React from 'react';
import {connect} from 'react-redux';
import {Table} from 'reactstrap';
import Entity from './entity';
import actions from '../actions';

class Entities extends React.Component {
  newEntity() {
    actions.newEntity();
  }

  render() {
    const {properties, entities} = this.props;
    return <React.Fragment><Table>
      <thead>
      <tr>
        <th style={{width: '1px'}}/>
        <th style={{width: '15rem'}}>
          Name
        </th>
        {/*<th>*/}
          {/*Resources*/}
        {/*</th>*/}
        <th>
          Properties
        </th>
      </tr>
      </thead>
      <tbody>
      {entities.map(e => <Entity key={e.id} entity={e} properties={properties}/>)}
      </tbody>
    </Table>
      <button className="btn btn-success" onClick={this.newEntity.bind(this)}>
        <i className="fa fa-plus" />
        {' '} New
      </button>
    </React.Fragment>;

  }
}

export default connect(({properties, entities}) => {
  return {properties, entities};
})(Entities);