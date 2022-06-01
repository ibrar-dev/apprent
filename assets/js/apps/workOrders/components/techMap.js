import React from 'react';
import {GoogleMap, Marker, withGoogleMap, withScriptjs} from 'react-google-maps';
import MarkerWithLabel from 'react-google-maps/lib/components/addons/MarkerWithLabel';
import TechIcon from './techIcon';

class Map extends React.Component {
  state = {};

  render() {
    const {property, techs, selectedId} = this.props;
    const propPosition = {lat: property.lat, lng: property.lng};
    return <GoogleMap
      defaultZoom={7}
      defaultCenter={propPosition}
    >
      <Marker position={propPosition}/>
      {techs.map(tech => <React.Fragment key={tech.id}>
        <MarkerWithLabel
          position={{lat: tech.lat, lng: tech.lng}}
          labelAnchor={new google.maps.Point(14, 42)}
        >
          <TechIcon tech={tech} selected={selectedId === tech.id}/>
        </MarkerWithLabel>
      </React.Fragment>)}
    </GoogleMap>
  }
}

export default withScriptjs(withGoogleMap(Map));
