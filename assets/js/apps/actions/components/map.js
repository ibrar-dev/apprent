import React from 'react';
import {GoogleMap, Marker, withGoogleMap, withScriptjs} from 'react-google-maps';

class ActionMap extends React.Component {
  render() {
    const {location} = this.props;
    const pos = {lat: parseFloat(location.lat), lng: parseFloat(location.lon)};
    return <GoogleMap defaultZoom={7}
                   defaultCenter={pos}>
          <Marker position={pos}/>
        </GoogleMap>;

  }
}

export default withScriptjs(withGoogleMap(ActionMap))