import React from 'react';
import {connect} from 'react-redux';
import Features from './features';
import FloorPlans from './floorPlans';

class FeaturesApp extends React.Component {
  render() {
    const {features, properties, property, floorPlans, mode} = this.props;
    const propertyFeatures = features.filter(f => f.property_id === property.id);
    const propertyFloorPlans = floorPlans.filter(f => f.property_id === property.id);
    return mode === 'features' ? <Features features={propertyFeatures}
                                           properties={properties}
                                           property={property}
                                           propertyName={property.name}/> :
      <FloorPlans features={propertyFeatures}
                  properties={properties}
                  property={property}
                  floorPlans={propertyFloorPlans}
                  propertyName={property.name}/>;

  }
}

export default connect(({features, properties, property, floorPlans, mode}) => {
  return {features, properties, property, floorPlans, mode};
})(FeaturesApp)