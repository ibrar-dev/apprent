import React from 'react';
import {GoogleMap, Marker, withGoogleMap, withScriptjs} from 'react-google-maps';
import MarkerWithLabel from 'react-google-maps/lib/components/addons/MarkerWithLabel';
import TechIcon from './techIcon';

class Map extends React.Component {
  state = {};

  render() {
    const {property, techs} = this.props;
    const propPosition = {lat: parseFloat(property.lat), lng: parseFloat(property.lng)};
    return <GoogleMap defaultZoom={7}
                      defaultCenter={propPosition}>
      <MarkerWithLabel position={propPosition}
                       labelAnchor={new google.maps.Point(40, 42)}>
        <TechIcon tech={{name: property.name}} color='#fff'/>
      </MarkerWithLabel>
      {techs.filter(t => t.lat).map(tech => <React.Fragment key={tech.id}>
        <MarkerWithLabel position={{lat: tech.lat, lng: tech.lng}}
                         labelAnchor={new google.maps.Point(40, 42)}>
          <TechIcon tech={tech}/>
        </MarkerWithLabel>
      </React.Fragment>)}
    </GoogleMap>
  }
}

export default withScriptjs(withGoogleMap(Map));