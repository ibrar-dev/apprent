import React from 'react';
import {connect} from 'react-redux';
import {Link} from 'react-router-dom';
import {Card, CardBody, CardText, CardHeader, CardFooter, Button, Media, Row, Col, CardImg, CardTitle} from 'reactstrap';
import moment from 'moment';
import icons from '../../../../components/flatIcons';
import Rating from '../rating';
import actions from '../../actions';
import QRCode from 'qrcode.react';

class ShowTech extends React.Component {
  state = {
    showQR: false
  };

  deleteTech() {
    if (confirm('Really delete this Tech?')) {
      actions.deleteTech(this.props.tech.id);
    }
  }

  toggleQR() {
    this.setState({...this.state, showQR: !this.state.showQR});
  }

  render() {
    const {tech, properties, toggle} = this.props;
    const {category_ids} = tech;
    const {showQR} = this.state;
    const propertyNames = properties.reduce((acc, property) => {
        return tech.property_ids.includes(property.id) ? acc.concat([property.name]) : acc;
    }, []);
    const stats = tech.stats || {};
    const monthStats = tech.month_stats || {};
    return <div className={`card alert-${tech.active ? '' : 'danger'}`}>
        <div className="row no-gutters">
          <div className="col-auto">
            <img src={tech.image || icons.noUserImage} className="img-fluid" style={{height: 100, width: 100}} alt="Tech profile photo" />
          </div>
          <div className="col">
            <div className="card-block px-2">
              <div className="d-flex justify-content-between">
                <h4 className="card-title"><b>{tech.name}</b> - {tech.type}</h4>
                <div className="right-most_stuff">
                  {tech.pass_code && <Button className="ml-1 mt-1" onClick={this.toggleQR.bind(this)} outline color="primary"><img src={icons.key} style={{height: 25, width: 25}} alt="View Passcode"/></Button>}
                  <Link to={`/techs/${tech.id}`}><Button className="ml-1 mt-1" outline color="info"><img src={icons.eye} style={{height: 25, width: 25}} alt="View Detailed Tech Info"/></Button></Link>
                  <Button className="ml-1 mt-1" onClick={actions.setPassCode.bind(null, tech)} outline color="success"><img src={icons.qr_code} style={{height: 25, width: 25}} alt="Reset Pass Code"/></Button>
                  <Button className="ml-1 mt-1" onClick={toggle} outline color="warning"><img src={icons.edit} style={{height: 25, width: 25}} alt="Edit Tech" /></Button>
                </div>
              </div>
              <div className="px-2">
                <Row>
                  <Col>
                    <Row>
                      <span>All Time Rating:{" "}</span>
                      <div>
                        <Rating rating={stats.rating}/>
                      </div>
                    </Row>
                    <Row>
                      <span>This Months Rating:{" "}</span>
                      <div>
                        <Rating rating={monthStats.rating} />
                      </div>
                    </Row>
                    {
                      category_ids.length === 0
                      &&(
                        <Row>
                        <span style={{color: "red"}}>
                        No categories assigned
                        </span>
                        </Row>
                        )
                      }
                  </Col>
                  <Col>
                    <Row>
                      <span>All Time Completion Time: {" "}</span>
                      <div>
                        {moment.duration(stats.completion_time, "seconds").humanize()}
                      </div>
                    </Row>
                    <Row>
                      <span>This Months Completion Time: {" "}</span>
                      <div>
                        {moment.duration(monthStats.completion_time, "seconds").humanize()}
                      </div>
                    </Row>
                  </Col>
                </Row>
              </div>
            </div>
          </div>
        </div>
        <div className="card-footer w-100 text-muted">
          {!showQR && propertyNames.map(p => <span key={p}>{p}{" "}</span>)}
          {showQR && tech.pass_code && <div>
            <p>{tech.pass_code}</p>
            <QRCode value={JSON.stringify({pass_code: tech.pass_code, url: location.host})} />
          </div>}
        </div>
      </div>
  }
}

export default connect(({orders}) => {
  return {orders};
})(ShowTech);
