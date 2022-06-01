import React from 'react';
import actions from '../actions';

class SaveButton extends React.Component {
  render() {
    return <button className="btn btn-success save-btn" onClick={actions.saveForm}>
      Save Form
    </button>
  }
}

export default SaveButton;