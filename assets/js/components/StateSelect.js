import React from 'react';
import LabeledSelect from './LabeledSelect';

class StateSelect extends React.Component {
  render() {
    return (
      <LabeledSelect {...this.props} options={USSTATES} />
    )
  }
}

export default StateSelect;