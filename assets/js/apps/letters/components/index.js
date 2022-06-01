import React from 'react';
import {connect} from "react-redux";
import Residents from './residents';
import NewTemplate from './newTemplate';
import Templates from './templates';
import TabbedBox from '../../../components/tabbedBox';
import PropertySelect from '../../../components/propertySelect';
import canEdit from '../../../components/canEdit';
import actions from "../actions";
import Preview from "./templates/preview";
import RecurringLetters from './recurringLetters';

const links = [
  {icon: false, data: Residents, label: 'Residents', id: 0},
  {icon: false, data: Templates, label: 'View/Edit Templates', id: 1},
  {icon: false, data: NewTemplate, label: 'New Template', id: 2},
  {icon: false, data: RecurringLetters, label: 'Scheduled Letters', id: 3}
];

class LettersApp extends React.Component {
  state = {mode: links[0]};

  setTab(mode) {
    this.setState({mode})
  }

  preview(template, data) {
    this.setState({preview: data ? {template, data} : null});
  }

  render() {
    const {properties, property} = this.props;

    if (properties.length == 0) {
      return (
        <p>Loading</p>
      )
    }

    const {mode, preview} = this.state;
    const fullAccess = canEdit(["Regional", "Accountant", "Super Admin"]);
    if (!fullAccess) return <>
      <PropertySelect property={property} properties={properties} onChange={actions.viewProperty}/>
      <Residents/>
    </>;
    return <>
      <PropertySelect property={property} properties={properties} onChange={actions.viewProperty}/>
      <TabbedBox links={links} active={mode.id} onNavigate={this.setTab.bind(this)}>
        <div className="ml-3">
          <mode.data back={this.setTab.bind(this, links[0])} preview={this.preview.bind(this)}/>
        </div>
        {preview && <Preview {...preview} toggle={this.preview.bind(this)}/>}
      </TabbedBox>
    </>
  }
}

export default connect(({properties, property}) => {
  return {properties, property}
})(LettersApp);
