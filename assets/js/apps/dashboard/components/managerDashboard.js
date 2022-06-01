import React, {Component} from 'react';
import {
  Row,
  Col,
  Card,
  CardBody,
  Collapse,
  Table,
  Badge,
} from 'reactstrap';
import {RingLoader} from "react-spinners";
import {connect} from "react-redux";
import actions from '../actions';
import DashboardModal from './dashboardModal';
import PropertySelect from '../../../components/propertySelect';

const percentage = (high, low) => {
  return ((low / high) * 100.0).toFixed(2);
};

class ManagerDashboard extends Component {
  state = {
    collapsed: false,
    modal: false,
    property_ids: [],
    selectedProperty: '',
    viewAll: false,
    showFile: false,
    url: '',
    full: false
  };

  toggleCollapsed() {
    this.setState({...this.state, collapsed: !this.state.collapsed})
  }

  setModalData(type) {
    this.setState({...this.state, modalOpen: !this.state.modalOpen, type: type})
  }

  toggle(event) {
    event.stopPropagation();
    this.setState({...this.state, propertyMenu: !this.state.propertyMenu});
  }


  showFiles() {
    const {property_ids} = this.state;
    const {properties} = this.props;
    const all_properties = property_ids.length ? property_ids : properties.map(p => p.id);
    actions.fetchPropertiesDocuments(all_properties);
    this.setState({showFile: true, propertyMenu: false})
  }

  toggleShowDOC() {
    this.setState({showFile: !this.state.showFile})
  }

  render() {
    const {propertyReport, properties, fetching, property} = this.props;

    if (properties.length == 0) {
      return (
        <p>Loading</p>
      )
    }

    const {maintenance_info, resident_info, property_info, alerts} = propertyReport;
    const {collapsed, modalOpen, type, viewAll, showFile} = this.state;
    return (
      <Row>
        {modalOpen && <DashboardModal toggle={this.setModalData.bind(this, null)} type={type}/>}
        <Col sm={12}>
          <div className={`d-flex justify-content-between mt-2 card-body py-0${collapsed ? ' mb-3' : ''}`}>
            <div className="d-flex align-items-center" style={{cursor: "pointer"}}
                 onClick={this.toggleCollapsed.bind(this)}>
              <h5 className="mb-0 mr-3" style={{color: '#666c7b'}}>Property Dashboard</h5>
              <i style={{color: '#39b157'}} className={`mt-1 fas fa-chevron-${collapsed ? "right" : "down"}`}/>
            </div>
            <div className="d-flex">
              <PropertySelect property={property} properties={properties} onChange={actions.viewProperty} />
            </div>
          </div>
          <Collapse isOpen={!collapsed}>
            <CardBody style={{}}>
              <Row>
                <Col>
                  <Card style={{height: 335, backgroundColor: "#fffbef"}}>
                    {fetching && <div className="m-auto">
                      <RingLoader size={65} color="#5dbd77"/>
                    </div>}
                    {!fetching && <React.Fragment>
                      <div className="d-flex justify-content-between">
                        <h5 className="light-text" style={{padding: 6, color: '#3a3b42'}}>Residents</h5>
                        <i style={{fontSize: 16, position: 'relative', top: 9, right: 9}} className="fas fa-users"/>
                      </div>
                      <Table hover>
                        <tbody>
                        <tr className="light-text"
                            onClick={resident_info ? this.setModalData.bind(this, "move_ins") : null}>
                          <th style={{borderColor: "#f1ebd9"}}>Move Ins</th>
                          <td style={{borderColor: "#f1ebd9"}} className="green-text">
                            <Badge style={{backgroundColor: "#e8c75c"}} pill>
                              {resident_info && resident_info.move_ins.length}
                            </Badge>
                          </td>
                          <td style={{borderColor: "#f1ebd9"}}/>
                        </tr>
                        <tr className="light-text"
                            onClick={resident_info ? this.setModalData.bind(this, "move_outs") : null}>
                          <th style={{borderColor: "#f1ebd9"}}>Move Outs</th>
                          <td style={{borderColor: "#f1ebd9"}} className="green-text">
                            <Badge style={{backgroundColor: "#e8c75c"}} pill>
                              {resident_info && resident_info.move_outs.length}
                            </Badge>
                          </td>
                          <td style={{borderColor: "#f1ebd9"}}/>
                        </tr>
                        <tr className="light-text"
                            onClick={resident_info ? this.setModalData.bind(this, "expiring_leases") : null}>
                          <th style={{borderColor: "#f1ebd9"}}>Expiring Leases (120 Days)</th>
                          <td style={{borderColor: "#f1ebd9"}} className="green-text">
                            <Badge style={{backgroundColor: "#e8c75c"}} pill>
                              {resident_info && resident_info.expiring_leases.length}
                            </Badge>
                          </td>
                          <td style={{borderColor: "#f1ebd9"}}/>
                        </tr>
                        <tr className="light-text"
                            onClick={resident_info ? this.setModalData.bind(this, "on_notice") : null}>
                          <th style={{borderColor: "#f1ebd9"}}>On Notice</th>
                          <td style={{borderColor: "#f1ebd9"}} className="green-text">
                            <Badge style={{backgroundColor: "#e8c75c"}} pill>
                              {resident_info && resident_info.on_notice.length}
                            </Badge>
                          </td>
                          <td style={{borderColor: "#f1ebd9"}}/>
                        </tr>
                        <tr className="light-text"
                            onClick={resident_info ? this.setModalData.bind(this, "todays_tours") : null}>
                          <th style={{borderColor: "#f1ebd9"}}>Todays Tours</th>
                          <td style={{borderColor: "#f1ebd9"}} className="green-text">
                            <Badge style={{backgroundColor: "#e8c75c"}} pill>
                              {resident_info && resident_info.todays_showings.length}
                            </Badge>
                          </td>
                          <td style={{borderColor: "#f1ebd9"}}/>
                        </tr>
                        <tr className="light-text"
                            onClick={maintenance_info ? this.setModalData.bind(this, "uncollected_packages") : null}>
                          <th style={{borderColor: "#f1ebd9"}}>Uncollected Packages</th>
                          <td style={{borderColor: "#f1ebd9"}} className="green-text">
                            <Badge style={{backgroundColor: "#e8c75c"}} pill>
                              {property_info && property_info.uncollected_packages.length}
                            </Badge>
                          </td>
                          <td style={{borderColor: "#f1ebd9"}}/>
                        </tr>
                        </tbody>
                      </Table>
                    </React.Fragment>}
                  </Card>
                </Col>
                <Col>
                  <Card style={{height: 335, backgroundColor: "#daf1e3"}}>
                    {fetching && <div className="m-auto">
                      <RingLoader size={65} color="#5dbd77"/>
                    </div>}
                    {!fetching && <React.Fragment>
                      <div className="d-flex justify-content-between">
                        <h5 className="light-text" style={{padding: 6, color: "#3a3b42"}}>Maintenance</h5>
                        <i style={{fontSize: 16, position: 'relative', top: 9, right: 9}} className="fas fa-tools"/>
                      </div>
                      <Table hover>
                        <tbody>
                        <tr className="light-text"
                            onClick={maintenance_info ? this.setModalData.bind(this, "open_orders") : null}>
                          <th style={{borderColor: "#c0e2c8"}}>Currently Open Orders</th>
                          <td style={{borderColor: "#c0e2c8"}} className="green-text">
                            <Badge style={{backgroundColor: "#6fc382"}} pill>
                              {maintenance_info && maintenance_info.currently_open.length}
                            </Badge>
                          </td>
                        </tr>
                        <tr className="light-text"
                            onClick={maintenance_info ? this.setModalData.bind(this, "paused_orders") : null}>
                          <th style={{borderColor: "#c0e2c8"}}>Currently Paused Orders</th>
                          <td style={{borderColor: "#c0e2c8"}} className="green-text">
                            <Badge style={{backgroundColor: "#6fc382"}} pill>
                              {maintenance_info && maintenance_info.currently_on_hold.length}
                            </Badge>
                          </td>
                        </tr>
                        <tr className="light-text"
                            onClick={maintenance_info ? this.setModalData.bind(this, "active_orders") : null}>
                          <th style={{borderColor: "#c0e2c8"}}>Currently Active Orders</th>
                          <td style={{borderColor: "#c0e2c8"}} className="green-text">
                            <Badge style={{backgroundColor: "#6fc382"}} pill>
                              {maintenance_info && maintenance_info.currently_in_progress.length}
                            </Badge>
                          </td>
                        </tr>
                        <tr className="light-text"
                            onClick={maintenance_info ? this.setModalData.bind(this, "not_inspected") : null}>
                          <th style={{borderColor: "#c0e2c8"}}>Units Not Yet Inspected</th>
                          <td style={{borderColor: "#c0e2c8"}} className="green-text">
                            <Badge style={{backgroundColor: "#6fc382"}} pill>
                              {maintenance_info && maintenance_info.not_yet_inspected_units && maintenance_info.not_yet_inspected_units.length}
                            </Badge>
                          </td>
                        </tr>
                        <tr className="light-text"
                            onClick={maintenance_info ? this.setModalData.bind(this, "make_readys") : null}>
                          <th style={{borderColor: "#c0e2c8"}}>Todays Make Ready Items</th>
                          <td style={{borderColor: "#c0e2c8"}} className="green-text"><Badge
                            style={{backgroundColor: "#6fc382"}}
                            pill>{maintenance_info && maintenance_info.todays_card_items.length}</Badge>
                          </td>
                        </tr>
                        <tr className="light-text"
                            onClick={maintenance_info ? this.setModalData.bind(this, "parts_pending") : null}>
                          <th style={{borderColor: "#c0e2c8"}}>Parts Pending</th>
                          <td style={{borderColor: "#c0e2c8"}} className="green-text"><Badge
                            style={{backgroundColor: "#6fc382"}}
                            pill>{maintenance_info && maintenance_info.pending_and_ordered_parts.length}</Badge>
                          </td>
                        </tr>
                        </tbody>
                      </Table>
                    </React.Fragment>}
                  </Card>
                </Col>
                <Col>
                  <Card style={{height: 335, backgroundColor: "#daebf1"}}>
                    {fetching && <div className="m-auto">
                      <RingLoader size={65} color="#5dbd77"/>
                    </div>}
                    {!fetching && <React.Fragment>
                      <div className="d-flex justify-content-between">
                        <h5 className="light-text" style={{padding: 6, color: "#3a3b42"}}>Property</h5>
                        <i style={{fontSize: 16, position: 'relative', top: 9, right: 9}} className="fas fa-home"/>
                      </div>
                      <Table hover>
                        <tbody>
                        <tr className="light-text">
                          <th style={{borderColor: "#c8dbef"}}>Total Units</th>
                          <td style={{borderColor: "#c8dbef"}} className="green-text">
                            <Badge style={{backgroundColor: "#8acae0"}} pill>
                              {property_info && property_info.units.length}
                            </Badge>
                          </td>
                          <td style={{borderColor: "#c8dbef"}}/>
                        </tr>
                        <tr className="light-text">
                          <th style={{borderColor: "#c8dbef"}}>Leased Units</th>
                          <td style={{borderColor: "#c8dbef"}} className="green-text">
                            <Badge style={{backgroundColor: "#8acae0"}} pill>
                              {/*NEED TO UPDATE THIS MATH*/}
                              {property_info && (property_info.units.length - property_info.available_units.length - property_info.model_units.length)}
                            </Badge>
                          </td>
                          <td style={{borderColor: "#c8dbef", color: "#67a9bf"}} className="green-text">
                            {property_info && property_info.calculations && property_info.calculations.leased}%
                          </td>
                        </tr>
                        <tr className="light-text">
                          <th style={{borderColor: "#c8dbef"}}>Occupied Units</th>
                          <td style={{borderColor: "#c8dbef"}} className="green-text">
                            <Badge style={{backgroundColor: "#8acae0"}} pill>
                              {property_info && property_info.occupied_units.length}
                            </Badge>
                          </td>
                          <td style={{borderColor: "#c8dbef", color: "#67a9bf"}}
                              className="green-text">{property_info && property_info.calculations && property_info.calculations.occ}%
                          </td>
                        </tr>
                        <tr className="light-text"
                            onClick={property_info ? this.setModalData.bind(this, "available_units") : null}>
                          <th style={{borderColor: "#c8dbef"}}>Available Units</th>
                          <td style={{borderColor: "#c8dbef"}} className="green-text">
                            <Badge style={{backgroundColor: "#8acae0"}} pill>
                              {property_info && property_info.available_units.length}
                            </Badge>
                          </td>
                          <td style={{borderColor: "#c8dbef"}}/>
                        </tr>
                        <tr className="light-text" onClick={property_info ? this.setModalData.bind(this, "preleased_units") : null}>
                          <th style={{borderColor: "#c8dbef"}}>Pre-Leased Units</th>
                          <td style={{borderColor: "#c8dbef"}} className="green-text">
                            <Badge style={{backgroundColor: "#8acae0"}} pill>
                              {property_info && property_info.preleased_units.length}
                            </Badge>
                          </td>
                          <td style={{borderColor: "#c8dbef"}}/>
                        </tr>
                        <tr className="light-text">
                          <th style={{borderColor: "#c8dbef"}}>Trend (30)</th>
                          <td style={{borderColor: "#c8dbef"}}/>
                          <td style={{borderColor: "#c8dbef", color: "#67a9bf"}} className="green-text">
                            {property_info && property_info.calculations && property_info.calculations.trend}%
                          </td>
                        </tr>
                        </tbody>
                      </Table>
                    </React.Fragment>}
                  </Card>
                </Col>
              </Row>
              <Row>
                <Col>
                  <Card id="alerts-dashboard" className="alert-danger">
                    {fetching && <div className="m-auto">
                      <RingLoader size={65} color="#5dbd77"/>
                    </div>}
                    {!fetching && <div>
                      <Row>
                        <Col>
                          <div className="d-flex justify-content-between">
                            <h5 className="light-text" style={{padding: 6, color: "#3a3b42"}}>Leases</h5>
                            <i style={{fontSize: 16, position: 'relative', top: 9, right: 9}}
                               className="fas fa-concierge-bell"/>
                          </div>
                          <Table hover>
                            <tbody>
                            <tr className="light-text"
                                onClick={alerts ? this.setModalData.bind(this, "no_charge_leases") : null}>
                              <th style={{borderColor: "#f3bbc1"}}>No Charges</th>
                              <td style={{borderColor: "#f3bbc1"}}>
                                <Badge color={alerts && alerts.no_charge_leases.length ? "danger" : "success"}>
                                  {alerts && alerts.no_charge_leases.length}
                                </Badge>
                              </td>
                            </tr>
                            <tr className="light-text"
                                onClick={propertyReport.alerts ? this.setModalData.bind(this, "past_move_outs") : null}>
                              <th style={{borderColor: "#f3bbc1"}}>Move Out Required</th>
                              <td style={{borderColor: "#f3bbc1"}}>
                                <Badge color={alerts && alerts.past_expected_move_out.length ? "danger" : "success"}>
                                  {alerts && alerts.past_expected_move_out.length}
                                </Badge>
                              </td>
                            </tr>
                            </tbody>
                          </Table>
                        </Col>
                        <Col>
                          <div className="d-flex justify-content-between">
                            <h5 className="light-text" style={{padding: 6, color: "#3a3b42"}}>Property</h5>
                            <i style={{fontSize: 16, top: 9, right: 9}} className="fas fa-igloo position-relative"/>
                          </div>
                          <Table hover>
                            <tbody>
                            <tr className="light-text"
                                onClick={propertyReport.alerts ? this.setModalData.bind(this, "no_default_charges") : null}>
                              <th style={{borderColor: "#f3bbc1"}}>Missing Default Charges</th>
                              <td style={{borderColor: "#f3bbc1"}}>
                                <Badge
                                  color={alerts && alerts.floorplans_with_no_default_charges.length ? "danger" : "success"}>
                                  {alerts && alerts.floorplans_with_no_default_charges.length ||
                                  <i className="fas fa-check"/>}
                                </Badge>
                              </td>
                            </tr>
                            </tbody>
                          </Table>
                        </Col>
                        <Col/>
                      </Row>
                    </div>}
                  </Card>
                </Col>
              </Row>
            </CardBody>
          </Collapse>
        </Col>
      </Row>
    )
  }
}

export default connect(({propertyReport, properties, specificProperties, documents, fetching, property}) => {
  return {propertyReport, properties, specificProperties, documents, fetching, property};
})(ManagerDashboard);
