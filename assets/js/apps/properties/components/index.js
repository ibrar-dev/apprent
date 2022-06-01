import React from "react";
import {connect} from "react-redux";
import actions from "../actions";
import Property from "./property";
import NewProperty from "./newProperty";
import {Button} from "reactstrap";
import PropertySelect from '../../../components/propertySelect';

class PropertiesApp extends React.Component {
  constructor(props) {
    super(props);
    this.state = {};
  }

  newProperty() {
    this.setState(
      {
        ...this.state,
        newPropertyOpen: !this.state.newPropertyOpen
      }
    );
  }

  saveNewProperty(property) {
    actions.createProperty(property).then(this.newProperty.bind(this));
  }

  render() {
    const {properties, property: prop} = this.props;
    const property = prop && properties.find(p => p.id === prop.id) || {};
    const {newPropertyOpen} = this.state;
    return (
      <React.Fragment>
        <PropertySelect
          defaultToFirst={true}
          property={property}
          properties={properties}
          onChange={actions.fetchProperty}
        />
        <div
          className="d-flex justify-content-end position-absolute"
          style={{top: 4, right: 12, zIndex: 100}}
        >
          <Button
            active={false}
            onClick={this.newProperty.bind(this)}
            size="sm"
            color="success"
          >
            <i className="fas fa-plus-circle"/>
            New Property
          </Button>
        </div>
        {
          property.id &&
            <Property
              property={prop}
              properties={properties}
              newProperty={this.newProperty.bind(this)}
            />
        }
        {
          newPropertyOpen &&
            <NewProperty
              accept={this.saveNewProperty.bind(this)}
              dismiss={this.newProperty.bind(this)}
            />
        }
      </React.Fragment>
    );
  }
}

export default connect(({properties, property}) => {
  return {properties, property}
})(PropertiesApp)
