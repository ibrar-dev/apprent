import React from 'react';
import {connect} from 'react-redux';
import TabbedBox from '../../../../../components/tabbedBox';
import Processor from './processor';
import {processors} from "./data";

const links = [
  {icon: false, data: 'cc', label: 'Credit Card Processor', id: 0},
  {icon: false, data: 'ba', label: 'Bank Account Processor', id: 1},
  {icon: false, data: 'lease', label: 'Lease Management', id: 2},
  {icon: false, data: 'screening', label: 'Tenant Screening', id: 3},
  {icon: false, data: 'management', label: 'Property Management', id: 4}
];

const validIndicator = (link, property, integrations) => {
  const integration = integrations.find(i => i.property_id === property.id && i.type === link.data);
  const valid = {...link, label: <div className="d-flex justify-content-between align-items-center">
      {link.label} <i className="fas fa-check-circle text-success"/>
    </div>};

  const invalid = {...link, label: <div className="d-flex justify-content-between align-items-center">
      {link.label} <i className="fas fa-exclamation-circle text-danger"/>
    </div>};

  if (!integration) return invalid;
  if (link.data === 'management' && !property.external_id) return invalid;
  const numKeys = processors[integration.name].length;
  const validKeys = integration.keys.every(k => k.length > 0 && k !== 'failed decrypt');
  if (integration.keys.length === numKeys && validKeys) return valid;
  return invalid;
};

class IntegrationsApp extends React.Component {
  state = {tab: links[0], property: {}};

  setTab(tab) {
    this.setState({tab});
  }

  setProperty(property) {
    this.setState({property})
  }

  propertyChanged(params) {
    this.setState({property: {...this.state.property, ...params}});
  }

  currentIntegration() {
    const {tab} = this.state;
    const {property, integrations} = this.props;
    if (property.id) {
      return integrations.find(i => {
        return i.property_id === property.id && i.type === tab.data;
      }) || {keys: [], name: '', property_id: property.id};
    }
    return {keys: [], name: '', property_id: property.id};
  }

  render() {
    const {tab} = this.state;
    const {integrations, property} = this.props;
    const integration = this.currentIntegration();
    return <TabbedBox links={links.map(link => validIndicator(link, property, integrations))}
                      active={tab.id}
                      onNavigate={this.setTab.bind(this)}>
      <div className="ml-4 mt-4">
        <Processor propertyId={property.id}
                   externalId={property.external_id}
                   parent={this}
                   processor={integration}
                   type={tab.data}/>
      </div>
    </TabbedBox>;
  }
}

export default connect(({integrations, property}) => ({integrations, property}))(IntegrationsApp)