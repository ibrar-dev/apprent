import React from 'react';
import {connect} from 'react-redux';
import actions from "../../../actions";

class ModeSwitch extends React.Component {
  render() {
    const {mode} = this.props;
    return <div style={{fontSize: '85%', marginRight: 3}}>
      <label className="m-0">
        <input type="radio" name="mode"
               checked={mode === 'features'}
               onChange={actions.setMode.bind(null, 'features')}/> Market Rent
      </label>
      <label className="nowrap m-0">
        <input type="radio" name="mode"
               checked={mode === 'floorPlans'}
               onChange={actions.setMode.bind(null, 'floorPlans')}/> Floor Plans
      </label>
    </div>
  }
}

export default connect(({mode}) => {
  return {mode};
})(ModeSwitch);