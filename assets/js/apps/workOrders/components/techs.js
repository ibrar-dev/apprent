import React from 'react';
import {Row, Col, Button} from 'reactstrap';
import actions from "../actions";
import TechMap from './techMap';
import Tech from './tech';

class Techs extends React.Component {
  state = {selectedId: null, selected: []};

  sendOffer() {
    const {orderId} = this.props;
    const {selected} = this.state;
    actions.sendOffer(selected, orderId).then(() => {
      this.setState({...this.state, selectedId: null, selected: []});
    });
  }

  render() {
    const {techs, property, offers, orderId, callbacks, select, selected, selectedId} = this.props;
    const connected = techs.reduce((techs, tech) => tech.lat ? techs.concat([tech]) : techs, []);
    return <Row>
      <Col sm={6}>
        <ul className="list-group mt-2">
          {techs.map(t => {
            const callback = callbacks.filter(c => c.tech_id === t.id)[0];
            return <Tech
              key={t.id}
              callback={callback}
              orderId={orderId}
              offer={offers.filter(o => o.tech_id === t.id)[0]}
              selected={selected.indexOf(t.id) > -1}
              select={select}
              tech={t}
            />;
          })}
        </ul>
      </Col>
      <Col sm={6}>
        <TechMap
          property={property}
          selectedId={selectedId}
          googleMapURL="https://maps.googleapis.com/maps/api/js?v=3.exp&libraries=geometry,drawing,places&key=AIzaSyAr30moXrrWMfu-pyeDabgPddKzLcMJO5w"
          loadingElement={<div style={{height: `100%`}}/>}
          containerElement={<div style={{height: `400px`}}/>}
          mapElement={<div style={{height: `100%`}}/>}
          techs={connected}
        />
      </Col>
    </Row>;
  }
}

export default Techs;
