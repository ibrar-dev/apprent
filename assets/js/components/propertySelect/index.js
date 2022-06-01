import React, {Component} from 'react';
import Select from '../../components/select';
import {getCookie, setCookie} from "../../utils/cookies";

class PropertyOption extends Component {
  render() {
    const {innerProps, data, getStyles} = this.props;
    return (
      <div
        {...innerProps}
        className={getStyles('option', this.props) + ' d-flex align-items-center pr-0 nav-link'}>
        <div
          className="mr-1 d-flex"
          style={{width: 17, height: 15}}>
          <img className="img-fluid" src={data.icon}/>
        </div>
        {data.label}
      </div>
    )
  }
}

class PropertyValue extends Component {
  render() {
    const {innerProps, getStyles, getValue, children} = this.props;
    const value = getValue()[0];
    return (
      <div
        {...innerProps}
        className={getStyles('singleValue', this.props) + ' d-flex align-items-center p-0 nav-link'}
      >
        <div className="mr-3 d-flex bg-white rounded-circle p-2" style={{width: 25, height: 25}}>
          <img className="img-fluid" src={value.icon}/>
        </div>
        {children}
      </div>
    )
  }
}

class PropertySelect extends Component {
  constructor(props) {
    super(props);
    const firstProperty = props.properties[0];
    let property;

    if (props.property?.id === -1 && props.defaultToFirst) {
      property = {
        name: firstProperty?.name,
        id: firstProperty?.id,
      }
    } else {
      property = JSON.parse(getCookie("property"));
    }

    if (property) {
      props.onChange(property);
    }
  }

  componentDidUpdate(prevProps) {
    const firstProperty = prevProps.properties[0];
    const property = {
      name: firstProperty?.name,
      id: firstProperty?.id
    };
    if (property.name && this.props.defaultToFirst && this.props.property.id === -1) {
      this.props.onChange(property);
    }
  }

  changeProperty({target: {value}}) {
    const {onChange, selectAll, properties} = this.props;
    let property;
    if (value) {
      if (selectAll && value === -1) {
        property = {name: "All Properties", id: -1, icon: ""}
      } else {
        property = properties.find((p) => p.id === value)
      }
    } else {
      property = value
    }

    if (property) {
      setCookie('property', JSON.stringify(property));
    }
    onChange(property);
  }

  render() {
    const {property, selectAll, style, properties} = this.props;
    const propertyOptions = properties.map(p => {
      return {label: p.name, value: p.id, icon: p.icon}
    });
    if (selectAll) {
      propertyOptions.unshift({
        label: 'All Properties',
        value: -1,
        icon: '/images/appLogo.png'
      });
    }
    return (
      <div id="property-select-app" style={{minWidth: 250, ...style}}>
        <Select
          value={property ? property.id : properties[0].id}
          components={{Option: PropertyOption, SingleValue: PropertyValue}}
          options={propertyOptions}
          style={{width: property ? 'auto' : '15'}}
          name="property"
          onChange={this.changeProperty.bind(this)}
        />
      </div>
    );
  }
}

export default PropertySelect;
