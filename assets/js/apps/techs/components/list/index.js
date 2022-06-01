import React, {Component} from 'react';
import {connect} from 'react-redux';
import {Row, Col, Button} from "reactstrap";
import actions from "../../actions";
import Tech from "./tech";
import NewTech from "./newTech";
import FilterInput from './filterInput';
import Pagination from '../../../../components/pagination';

class TechsApp extends Component {
  state = {
    filter: '',
    filterBy: 'name',
    stateProperties: [],
    enabledTechsOnly: true
  };

  newTech() {
    this.setState({...this.state, newTechOpen: true});
  }

  closeNewTech() {
    this.setState({...this.state, newTechOpen: false});
  }

  updateFilter({target: {value}}) {
    const newState = {...this.state, filter: value};
    if (this.state.filterBy === 'property') {
      const tester = new RegExp(value, 'i');
      newState.stateProperties = this.props.properties.reduce((acc, p) => {
        return tester.test(p.name) ? acc.concat([p.id]) : acc;
      }, []);
    }
    this.setState(newState);
  }

  updateFilterBy(value) {
    const propertyList = [];
    this.props.properties.map(p => propertyList.push(p.id));
    this.setState({...this.state, filterBy: value, filter: '', stateProperties: propertyList});
  }

  toggleTechs() {
    this.setState({...this.state, enabledTechsOnly: !this.state.enabledTechsOnly});
  }

  techFilter(filter, tech) {
    switch (this.state.filterBy) {
      case 'name':
        return filter.test(tech.name);
      default:
        return tech.property_ids.some(id => this.state.stateProperties.includes(id));
    }
  }

  render() {
    // linee 79 onClick={actions.setMode.bind(null, 'map')}
    const {newTechOpen, filter, enabledTechsOnly} = this.state;
    const regexFilter = new RegExp(filter, 'i');
    let {techs, properties} = this.props;
    if (enabledTechsOnly) techs = techs.filter(tech => tech.active);
    const collection = techs.filter(this.techFilter.bind(this, regexFilter));
    return <>
      {newTechOpen && <NewTech cancel={this.closeNewTech.bind(this)}
                               properties={properties}/>}
      <Pagination collection={collection}
                  type="row"
                  component={Tech}
                  title={<div>
                    <Button color="info" onClick={this.newTech.bind(this)}>
                      Add New
                    </Button>
                    <Button className="ml-2" color="success" onClick={() => this.props.history.push("/techs/map")}>
                      View Map(s)
                    </Button>
                    <Button className="ml-2" onClick={this.toggleTechs.bind(this)}>
                      {enabledTechsOnly ? 'View' : 'Hide'}{" "}Disabled Techs
                    </Button>
                  </div>}
                  filters={<FilterInput filterType={this.state.filterBy}
                                        updateFilterBy={this.updateFilterBy.bind(this)}
                                        updateFilter={this.updateFilter.bind(this)}
                                        filterValue={this.state.filter}/>}
                  field="tech"/>
    </>;
  }
}

export default connect(({techs, properties, filter, categories}) => {
  return {techs, properties, filter, categories};
})(TechsApp)