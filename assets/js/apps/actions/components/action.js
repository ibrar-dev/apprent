import React from 'react';
import moment from 'moment';
import actions from '../actions';
import ActionMap from './map';
import TechMap from "../../workOrders/components/techMap";
import {Popover, PopoverBody, Input, UncontrolledPopover, Button} from "reactstrap";
import {JsonTable} from 'react-json-to-html';

class Action extends React.Component {
  state = {};

  geolocate() {
    const {action} = this.props;
    actions.geolocate(action).then(r => {
      if (r.data.status === "success") {
        this.setState({location: r.data});
      }
    })
  }

  toggleMap() {
    this.setState({mapOpen: !this.state.mapOpen});
  }

  toggleParams() {
    this.setState({paramsOpen: !this.state.paramsOpen});
  }

  render() {
    const {action} = this.props;
    const {location, mapOpen, paramsOpen} = this.state;
    return <tr>
      <td>
        {moment.unix(action.ts).format('YYYY-MM-DD h:mm A')}
      </td>
      <td>
        {action.admin}
      </td>
      <td>
        <div className="d-inline-block mr-2">{action.ip}</div>
        {!location && <a onClick={this.geolocate.bind(this)}>
          Locate
        </a>}
        {location && <div className="d-inline-block">
          {location.city}, {location.country}
          <a onClick={this.toggleMap.bind(this)} id={`map-button-${action.id}`} className="ml-2">
            <i className="fas fa-map-marked-alt"/>
          </a>
          <Popover placement="right" isOpen={mapOpen} target={`map-button-${action.id}`}
                   toggle={this.toggleMap.bind(this)} className="popover-max">
            <PopoverBody>
              {mapOpen && <ActionMap location={location}
                                     toggle={this.toggleMap.bind(this)}
                                     googleMapURL="https://maps.googleapis.com/maps/api/js?v=3.exp&libraries=geometry,drawing,places&key=AIzaSyAr30moXrrWMfu-pyeDabgPddKzLcMJO5w"
                                     loadingElement={<div style={{height: `100%`}}/>}
                                     containerElement={<div style={{height: `400px`, width: 400}}/>}
                                     mapElement={<div style={{height: `100%`}}/>}

              />}
            </PopoverBody>
          </Popover>
        </div>}
      </td>
      <td>
        {action.description}
      </td>
      <td>
        <Button size='sm' id={`params-${action.id}`} onClick={this.toggleParams.bind(this)} style={{cursor: 'pointer'}}>Details</Button>
          <Popover isOpen={paramsOpen} toggle={this.toggleParams.bind(this)} className="popover-max" placement="left-start" target={`params-${action.id}`}>
            <PopoverBody>
              <JsonTable json={JSON.stringify(action.params)} />
            </PopoverBody>
          </Popover>
      </td>
    </tr>;
  }
}

export default Action;
