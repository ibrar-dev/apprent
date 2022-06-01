import React from 'react';
import {connect} from 'react-redux';
import {Card, CardHeader, CardBody, Button} from 'reactstrap';
import Prospect from './prospect';
import NewProspect from './newProspect';
import Search from './searchFilter';
import ContactEmail from './contactEmail';
import actions from "../actions";
import PropertySelect from '../../../components/propertySelect';

class ProspectsApp extends React.Component {
  state = {
    filter: '',
    filterBy: 'name',
    stateProperties: []
  };

  componentWillReceiveProps() {
    this.setState({...this.state, filter: ''});
  }

  updateFilter({target: {value}}) {
    this.setState({...this.state, filter: value});
  }

  toggleNewProspect() {
    this.setState({...this.state, newProspect: !this.state.newProspect});
  }

  toggleModal(p) {
    this.setState({...this.state, contactModal: !this.state.contactModal, prospect: p})
  }

  prospectFilter(filter, prospect) {
    switch (this.state.filterBy) {
      case 'name':
        return filter.test(prospect.name);
      default:
        return tech.property_ids.some(id => this.state.stateProperties.includes(id));
    }
  }

  render() {
    const {newProspect, filter, contactModal, prospect} = this.state;
    const {prospects, agents, property, properties} = this.props;

    if (properties.length === 0) {
      return (
        <p>Loading</p>
      )
    }

    const regexFilter = new RegExp(filter, 'i');
    return <Card className="h-100 border-left-0 rounded-0">
      <CardHeader className="d-flex justify-content-between align-items-center" style={{height: 60}}>
        <PropertySelect property={property} properties={properties} onChange={actions.setProperty}/>
        <div className="d-flex align-items-center">
          <div className="nowrap mr-2">{prospects.length} Prospects</div>
          <Search updateFilter={this.updateFilter.bind(this)} filterValue={this.state.filter}> </Search>
          <Button onClick={this.toggleNewProspect.bind(this)}
                  size="sm"
                  className="m-0 nowrap"
                  color="success">
            <i className="fas fa-plus-circle"/> New Prospect
          </Button>
        </div>
      </CardHeader>
      {contactModal && prospect && <ContactEmail toggle={this.toggleModal.bind(this, prospect)} prospect={prospect}/>}
      <CardBody>
        {prospects.filter(t => this.prospectFilter(regexFilter, t)).map(p => <Prospect key={p.id} prospect={p}
                                                                                       agents={agents}
                                                                                       toggle={this.toggleModal.bind(this, p)}/>)}
        {newProspect && <NewProspect toggle={this.toggleNewProspect.bind(this)}/>}
      </CardBody>
    </Card>;
  }
}

export default connect(({property, properties, prospects, agents}) => {
  const pr = prospects.filter(p => p.property.id === property.id);
  return {property, properties, prospects: pr, agents};
})(ProspectsApp);
