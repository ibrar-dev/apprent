import React from 'react';
import {connect} from 'react-redux';
import {Row, Col, Button, ButtonDropdown, DropdownToggle, DropdownMenu} from 'reactstrap';
import Map from './map';
import {GoogleMap, Marker, withScriptjs, withGoogleMap} from 'react-google-maps';

class Maps extends React.Component {
  state = {cP: 0};

    goBack(){
        this.props.history.push("/techs")
    }

    findPlace(idx){
        this.setState({cP: idx})
    }

  render() {
      const {techs, properties} = this.props;
      // const techLocation = techs.map((tech) =>  />);
      const {cP} = this.state;
      if (properties[cP] && properties[cP].lat) {

          const MyMapComponent = withScriptjs(withGoogleMap((props) => {
                  return <GoogleMap
                      defaultZoom={15}
                      defaultCenter={{lat: props.lat, lng: props.lng}}
                  >
                      <Marker options={{icon: {url: props.propertyImage, scaledSize: {width: 60, height: 60}, scale: 2}}} position={{lat: props.lat, lng: props.lng}}/>
                      {props.techs && props.techs.map(tech =>
                          tech.lat ? <Marker
                              options={{icon: {url: "https://cdn3.iconfinder.com/data/icons/gray-user-toolbar/512/worker-512.png", scaledSize: {width: 20, height: 20}}}}
                              position={{lat: parseFloat(tech.lat), lng: parseFloat(tech.lng)}} /> : null
                      )}
                  </GoogleMap>
              }
          ));

      return (
          <div>
              <Button onClick={this.goBack.bind(this)}>Back</Button>
          <MyMapComponent
              googleMapURL="https://maps.googleapis.com/maps/api/js?v=3.exp&libraries=geometry,drawing,places&key=AIzaSyAr30moXrrWMfu-pyeDabgPddKzLcMJO5w"
                loadingElement={<div style={{height: `100%`}}/>}
                containerElement={<div style={{height: `400px`}}/>}
                mapElement={<div style={{height: `100%`}}/>}
              lng={parseFloat(properties[cP].lng)}
              lat={parseFloat(properties[cP].lat)}
              techs={techs}
              propertyImage={properties[cP].icon}
          />
              <div className="row">
                  {properties && properties.map((property,i) => (
                      <Col sm={3} key={property.id}>
                          <Button style={{width: 220, height: 60}} outline block color="success" onClick={this.findPlace.bind(this,i)} className="d-flex justify-content-between">
                              <div>{property.icon && <img src={property.icon} style={{width: 45, height: 45, borderRadius: 45}} alt=""/>}</div>
                              <span>{property.name}</span>
                          </Button>
                      </Col>
                  ))}
              </div>
          </div>
      )
  }else{
          return <div>
              <Button onClick={this.goBack.bind(this)}>Back</Button>
          </div>;
      }

  }
}

export default connect(({techs, properties}) => {
  return {techs, properties}
})(Maps);