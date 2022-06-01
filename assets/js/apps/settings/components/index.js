import React from "react";
import TabbedBox from '../../../components/tabbedBox';
// import Banks from './banks';
import Damages from './damages';
import MoveOutReasons from './moveOutReasons';
import CredentialSets from './credentialSets';
import actions from '../actions';

const links = [
  // {icon: false, data: Banks, action: 'Banks', label: 'Banks', id: 1},
  {icon: false, data: Damages, action: 'Damages', label: 'Damages', id: 2},
  {icon: false, data: MoveOutReasons, action: 'MoveOutReasons', label: 'Move Out Reasons', id: 3},
  {icon: false, data: CredentialSets, action: 'CredentialSets', label: 'Integrations', id: 4}
];

class SettingsApp extends React.Component {
  state = {mode: links[0]};

  setMode(mode) {
    actions[`fetch${mode.action}`]();
    this.setState({mode});
  }

  render() {
    const {mode} = this.state;
    return <TabbedBox links={links}
                      active={mode.id}
                      onNavigate={this.setMode.bind(this)}>
      <mode.data/>
    </TabbedBox>;
  }
}

export default SettingsApp;