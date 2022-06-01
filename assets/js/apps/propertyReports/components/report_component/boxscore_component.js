import {Component} from "react";
import React from "react";
import Lease from './lease'
import {Card, CardBody, CardHeader, Col, Modal, Row} from "reactstrap";
import moment from 'moment';

export class FloorPlanInfo extends Component {
    render(){
        const {floor_plan: {type,reno, renoOc, nr, nu, down, vr, vu, occ, a, total, rent, area}} = this.props;
        const unOccupancy = (down + vr + vu) / total;
        const occupancy = (occ + nr + nu)/ total;
        const renoOccupancy = (occ - renoOc)/total;
        const leased = vr/ total;
        const avgFt = (area / total).toFixed(2);
        const avgRent = (rent / total).toFixed(2);
        return <tr>
            <td>{type}</td>
            <td>{avgFt}</td>
            <td>{avgRent}</td>
            <td>{total}</td>
            <td>{occ}</td>
            <td>{a}</td>
            <td>{reno}</td>
            <td>{down}</td>
            <td>{vu}</td>
            <td>{vr}</td>
            <td>{nu}</td>
            <td>{nr}</td>
            <td>{(unOccupancy * 100).toFixed(2)}</td>
            <td>{(occupancy * 100).toFixed(2)}</td>
            <td>{(renoOccupancy * 100).toFixed(2)}</td>
            <td>{((occupancy + leased) * 100).toFixed(2)}</td>
        </tr>
    }
}

export class FirstContact extends Component {
    state = {applicants: '#475f78', tours: '#475f78', modal: false, leases: []}
    hover(field, property){
        this.setState({[field]: property})
    }

    showLeases(type){
        this.setState({...this.state, modal: true, type: type})
    }

    toggleModal(){
        this.setState({...this.state, modal: !this.state.modal})
    }

    getContactType(type){
        const {contact} = this.props;
        return <>
            <Row>
                <Col style={{fontWeight: 800}}>Name</Col>
                <Col style={{fontWeight: 800}}>Showing Date</Col>
                <Col style={{fontWeight: 800}}>Start Time</Col>
                <Col style={{fontWeight: 800}}>End Time</Col>
                <Col style={{fontWeight: 800}}>Contact Type</Col>
            </Row>
            {contact[type].map(t => {
                return <Row key={t.id}>
                    <Col>{t.name}</Col>
                    <Col>{t.date}</Col>
                    <Col>{t.start_time}</Col>
                    <Col>{t.end_time}</Col>
                    <Col>{t.contact_type}</Col>
            </Row>})}
        </>
    }

    getApplicantType(type){
        const {contact} = this.props;
        return <>
                {contact[type].map(a => {
                    return <Row key={a.id} className="mb-2 ml-2">
                        <Col>
                            <Row><strong>Name</strong></Row>
                            <Row>{a.name}</Row>
                        </Col>
                        <Col>
                            <Row>
                                <Col>
                                    <strong>Submitted:</strong> {moment(a.application_submitted).format("MMM Do YY")}
                                    <strong className="ml-2">Status:</strong> {a.status}
                                </Col>
                            </Row>
                            <Row>
                                <Col>
                                    <strong>Cell:</strong> {a.cell_phone}
                                    <strong className="ml-2">Home:</strong> {a.home_phone}
                                </Col>
                            </Row>
                            <Row>
                                <Col>
                                    <strong>Email:</strong> {a.email}
                                    <strong className="ml-2">DOB:</strong> {a.dob}
                                </Col>
                            </Row>
                        </Col>
                    </Row>
                })}
        </>
    }

    getData(type){
        switch(type){
            case "phone":
                return this.getContactType(type);
            case "walkin":
                return this.getContactType(type);
            case "electronic":
                return this.getContactType(type);
            case "other":
                return this.getContactType(type);
            case "show":
                return this.getContactType(type);
            case "applied":
                return this.getApplicantType(type);
            case "approved":
                return this.getApplicantType(type);
            default:
                return null;
        }
    }

    render(){
        const {contact} = this.props;
        const {modal, type} = this.state;
        return <tr>
            <td>
                {contact.type}
            </td>
            <td>
                <a style={{color: this.state.phone}}
                   onClick={contact.phone && contact.phone.length ? this.showLeases.bind(this, "phone") : null}
                   onMouseEnter={this.hover.bind(this, 'phone', '#0056b3')}
                   onMouseLeave={this.hover.bind(this, 'phone', '#475f78')}>{contact.phone && contact.phone.length}</a>
            </td>
            <td>
                <a style={{color: this.state.walkin}}
                   onClick={contact.walkin && contact.walkin.length ? this.showLeases.bind(this, "walkin") : null}
                   onMouseEnter={this.hover.bind(this, 'walkin', '#0056b3')}
                   onMouseLeave={this.hover.bind(this, 'walkin', '#475f78')}>{contact.walkin && contact.walkin.length}</a>
            </td>
            <td>
                <a style={{color: this.state.electronic}}
                   onClick={contact.electronic && contact.electronic.length ? this.showLeases.bind(this, "electronic") : null}
                   onMouseEnter={this.hover.bind(this, 'electronic', '#0056b3')}
                   onMouseLeave={this.hover.bind(this, 'electronic', '#475f78')}>{contact.electronic && contact.electronic.length}</a>
            </td>
            <td>
                <a style={{color: this.state.other}}
                   onClick={contact.other && contact.other.length ? this.showLeases.bind(this, "other") : null}
                   onMouseEnter={this.hover.bind(this, 'other', '#0056b3')}
                   onMouseLeave={this.hover.bind(this, 'other', '#475f78')}>{contact.other && contact.other.length}</a>
            </td>
            <td>
                <a style={{color: this.state.web}}
                   onClick={contact.web && contact.web.length ? this.showLeases.bind(this, "web") : null}
                   onMouseEnter={this.hover.bind(this, 'web', '#0056b3')}
                   onMouseLeave={this.hover.bind(this, 'web', '#475f78')}>{contact.web && contact.web.length}</a>
            </td>
            <td>
                <a style={{color: this.state.show}}
                   onClick={contact.show && contact.show.length ? this.showLeases.bind(this, "show") : null}
                   onMouseEnter={this.hover.bind(this, 'show', '#0056b3')}
                   onMouseLeave={this.hover.bind(this, 'show', '#475f78')}>{contact.show && contact.show.length}</a>
            </td>
            <td>
                <a style={{color: this.state.applied}}
                   onClick={contact.applied && contact.applied.length ? this.showLeases.bind(this, "applied") : null}
                   onMouseEnter={this.hover.bind(this, 'applied', '#0056b3')}
                   onMouseLeave={this.hover.bind(this, 'applied', '#475f78')}>{contact.applied && contact.applied.length}</a>
            </td>
            <td>
                <a style={{color: this.state.approved}}
                   onClick={contact.approved && contact.approved.length ? this.showLeases.bind(this, "approved") : null}
                   onMouseEnter={this.hover.bind(this, 'approved', '#0056b3')}
                   onMouseLeave={this.hover.bind(this, 'approved', '#475f78')}>{contact.approved && contact.approved.length}</a>
            </td>

            <Modal className="modal-xl" isOpen={modal} toggle={this.toggleModal.bind(this)}>
                <Card>
                    <CardHeader>{type}</CardHeader>
                    <CardBody>
                        {this.getData(type)}
                    </CardBody>
                </Card>
            </Modal>
        </tr>
    }
}