import React from 'react';
import {connect} from "react-redux";
import {CardHeader} from "reactstrap";
import PropertySelect from "../../../components/propertySelect";
import Select from "../../../components/select";
import actions from "../actions";

const residentOptions = [
  {label: 'past', value: 'past'},
  {label: 'current', value: 'current'},
  {label: 'future', value: 'future'}
];

class Header extends React.Component {
  state = {residentType: 'current'};

  selectProperty(property) {
    this.setState({property});
    actions.fetchResidents(property.id, this.state.residentType);
  }

  selectResidentType({target: {value}}) {
    this.setState({residentType: value});
    actions.fetchResidents(this.state.property.id, value);
  }

  render() {
    const {residentType, property} = this.state;
    const {properties} = this.props;

    if (properties.length == 0) {
      return (
        <p>Loading</p>
      )
    }

    return <CardHeader className="p-0 d-flex justify-content-between align-items-center">
      <PropertySelect onChange={this.selectProperty.bind(this)} property={property} properties={properties}/>
      <div style={{width: 200}}>
        <Select options={residentOptions} value={residentType} className="rounded-0"
                onChange={this.selectResidentType.bind(this)}/>
      </div>
    </CardHeader>;
  }
}

export default connect(({properties}) => {
  return {properties}
})(Header)
