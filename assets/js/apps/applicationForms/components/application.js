import React from 'react';
import moment from 'moment';
import {Card, CardHeader, CardBody, Row, Col, Modal, ModalBody, ModalHeader, Button} from 'reactstrap';
import ExportModal from "./exportModal";
import Select from "../../../components/select";
import actions from "../actions";
import CreateDocument from "./createDocument";
import canEdit from '../../../components/canEdit';
import PreviewModal from './previewModal';
import {toCurr} from "../../../utils";
import MemoCard from './application/memoCard';

class Application extends React.Component {
  constructor(props) {
  super(props);
    this.state = {
      currentModal: "",
    };
    this.setCurrentModal = this.setCurrentModal.bind(this);
  }

  setCurrentModal(name) {
    this.setState({currentModal: name});
  }

  saveUnit() {
    const {unit_id} = this.state;
    const {application} = this.props;
    application.move_in.unit_id = unit_id;
    actions.updateApplication(application);
  }

  change({target: {name, value}}) {
    this.setState({...this.state, [name]: value});
  }

  generateForm(){
    const {application} = this.props;
    const leaseHolder = application.occupants.filter(o => o.status === "Lease Holder").map(l => l.id);
    actions.generateForm({person_id: leaseHolder, property_id: application.property.id}).then(r => {
      this.setState({...this.state, preview: r.data.pdf});
    });
  }

  toggleForm() {
    this.setState({...this.state, preview: null})
  }

  render() {
    const {application, history, units} = this.props;
    const {preview, currentModal} = this.state;
    return <Card>
      <CardBody>
        {preview && <PreviewModal preview={preview} toggle={this.toggleForm.bind(this)} />}
        <Row>
          <Col md={4} xl={3} className="d-flex">
            <div className="d-flex flex-column justify-content-center p-4 card card-header w-100">
              <img alt={application.property.name} className="img-fluid" src={application.property.logo}/>
              <h3 className="text-center">
                Submitted {moment.utc(application.inserted_at).local().format("MMMM DD, YYYY")}
              </h3>
              <div className="d-flex justify-content-center">
                <a target="_blank" href={`/applications/${application.id}/edit`} className="btn btn-info">
                  Edit
                </a>
                <Button className="ml-3" color="danger" onClick={() => history.push('/applications', {})}>
                  Back
                </Button>
                {application.tenancy_id &&
                <a className="btn btn-success ml-3" href={`/tenants/${application.tenancy_id}`}>
                  Ledger
                </a>}
                {!application.tenancy_id &&
                <a className="btn btn-success ml-3" href={`/applicants/${application.id}`}>
                  Ledger
                </a>}
              </div>
            </div>
          </Col>
          {application.occupants.map(person => {
            return <Col md={4} xl={3} key={person.id}>
              <Card>
                <CardHeader>{person.status}</CardHeader>
                <CardBody>
                  <ul className="list-unstyled">
                    <li>
                      <b>Name:</b> {person.full_name}
                    </li>
                    <li>
                      <b>Email:</b> {person.email}
                    </li>
                    <li>
                      <b>SSN:</b> {
                        application.property.applicant_info_visible ?
                          person.ssn :
                          canEdit(["Super Admin", "Regional"] ? person.ssn : "***-**-****")
                      }
                    </li>
                    <li>
                      <b>DOB:</b> {person.dob}
                    </li>
                    <li>
                      <b>Home Phone:</b> {person.home_phone}
                    </li>
                    <li>
                      <b>Work Phone:</b> {person.work_phone}
                    </li>
                    <li>
                      <b>Cell Phone:</b> {person.cell_phone}
                    </li>
                    <li>
                      <b>Driver License:</b> {person.dl_number}
                    </li>
                    <li>
                      <b>DL State:</b> {person.dl_state}
                    </li>
                  </ul>
                </CardBody>
              </Card>
            </Col>
          })}
          <Col>
            <Button onClick={this.generateForm.bind(this)}>Generate Rental Verification</Button>
          </Col>
        </Row>
        <Row>
          <Col>
            <Card>
              <CardHeader>Move In</CardHeader>
              <CardBody>
                <ul className="list-unstyled m-0">
                  <li><b>Move In Date:</b> {application.move_in.expected_move_in}</li>
                  <li className="d-flex">
                    {application.unit && <span><b>Unit: </b> {application.unit}</span>}
                    {!application.unit && <>
                      <div className="w-50 mr-2">
                        <Select
                          value={application.move_in.unit_id}
                          placeholder="Unit"
                          name="unit_id"
                          onChange={this.change.bind(this)}
                          options={units.map(u => {
                            return {value: u.id, label: u.number}
                          })}
                        />
                      </div>
                      <Button
                        onClick={this.saveUnit.bind(this)}
                        outline
                        color="success"
                      >
                        Save
                      </Button>
                    </>}
                  </li>
                </ul>
              </CardBody>
            </Card>
          </Col>
          <Col>
            <MemoCard
              onClose={() => this.setCurrentModal("")}
              onOpen={() => this.setCurrentModal("memo")}
              application={application}
              currentModal={currentModal}
            />
          </Col>
        </Row>
        <Row>
          <Col>
            <Card>
              <CardHeader>Previous Residencies</CardHeader>
              <CardBody>
                {application.histories.map((history, i) => {
                  return <ul key={history.id} className={`list-unstyled m-0 ${i > 0 ? 'mt-4' : ''}`}>
                    <li>
                      <b>Address:</b> {history.address}
                    </li>
                    {history.rent && <>
                      <li>
                        <b>Rental Amount:</b> {history.rental_amount}
                      </li>
                      <li>
                        <b>Landlord Name:</b> {history.landlord_name}
                      </li>
                      <li>
                        <b>Landlord Phone:</b> {history.landlord_phone}
                      </li>
                      <li>
                        <b>Landlord Email:</b> {history.landlord_email}
                      </li>
                    </>}
                  </ul>;
                })}
              </CardBody>
            </Card>
          </Col>
          <Col>
            <Card>
              <CardHeader>Pets &amp; Vehicles</CardHeader>
              <CardBody>
                <div className="w-50 float-left">
                  {application.pets.map(pet => <ul key={pet.id} className="list-unstyled">
                    <li>
                      <b>Name:</b> {pet.name}
                    </li>
                    <li>
                      <b>Weight:</b> {pet.weight} lb
                    </li>
                    <li>
                      <b>Type:</b> {pet.type}
                    </li>
                    <li>
                      <b>Breed:</b> {pet.breed}
                    </li>
                  </ul>)}
                </div>
                <div className="w-50 float-left">
                  {application.vehicles.map(vehicle => <ul key={vehicle.id} className="list-unstyled">
                    <li>
                      <b>Color:</b> {vehicle.color}
                    </li>
                    <li>
                      <b>Make/Model:</b> {vehicle.make_model}
                    </li>
                    <li>
                      <b>License Plate:</b> {vehicle.license_plate}
                    </li>
                    <li>
                      <b>State:</b> {vehicle.state}
                    </li>
                  </ul>)}
                </div>
              </CardBody>
            </Card>
          </Col>
        </Row>
        <Row>
          <Col>
            <Card>
              <CardHeader>Employment Information</CardHeader>
              <CardBody>
                {application.employments.map((employment, i) => {
                  return <ul key={employment.id} className={`list-unstyled m-0 ${i > 0 ? 'mt-4' : ''}`}>
                    <li>
                      <b>Employer:</b> {employment.employer}
                    </li>
                    <li>
                      <b>Address:</b> {employment.address}
                    </li>
                    <li>
                      <b>Phone:</b> {employment.phone}
                    </li>
                    <li>
                      <b>Email:</b> {employment.email}
                    </li>
                    <li>
                      <b>Supervisor:</b> {employment.supervisor}
                    </li>
                    <li>
                      <b>Duration:</b> {employment.duration}
                    </li>
                    <li>
                      <b>Salary:</b> ${employment.salary}/month
                    </li>
                  </ul>;
                })}
                {application.income && <div>
                  <p className="m-0 mt-4" style={{textDecoration: 'underline'}}>Misc. Income</p>
                  <ul className="list-unstyled mt-2 mb-0">
                    <li><b>Description:</b> {application.income.description}</li>
                    <li><b>Salary:</b> {application.income.salary}</li>
                  </ul>
                </div>}
              </CardBody>
            </Card>
          </Col>
          <Col>
            <Card>
              <Modal isOpen={currentModal === "document"} toggle={() => this.setCurrentModal("")} size="lg">
                <ModalHeader>Create New Document</ModalHeader>
                <ModalBody>
                  <CreateDocument application={application}/>
                </ModalBody>
              </Modal>
              <CardHeader className="d-flex justify-content-between">
                <div>Documents</div>
                <a onClick={() => this.setCurrentModal("document")}>ADD</a>
              </CardHeader>
              <CardBody>
                {application.documents.map(document => <ul key={document.id} className="list-unstyled">
                  <li>
                    <b>{document.type}:</b>
                  </li>
                  <li>
                    <a href={`/api/rent_apply_documents/${document.id}`}>Download</a>
                  </li>
                  <li>
                    <a href={document.url} target="_blank">View</a>
                  </li>
                </ul>)}
              </CardBody>
            </Card>
          </Col>
        </Row>
        <Row>
          <Col>
            <Card>
              <CardHeader>Emergency Contacts</CardHeader>
              <CardBody>
                {application.emergency_contacts.map(contact => <ul key={contact.id} className="list-unstyled">
                  <li>
                    <b>Name:</b> {contact.name}
                  </li>
                  <li>
                    <b>Relationship:</b> {contact.relationship}
                  </li>
                  <li>
                    <b>Email:</b> {contact.email}
                  </li>
                  <li>
                    <b>Phone:</b> {contact.phone}
                  </li>
                </ul>)}
              </CardBody>
            </Card>
          </Col>
          <Col>
            <Card>
              <CardHeader className="d-flex justify-content-between">
                <div>Payments</div>
                {/*<a onClick={() => this.setCurrentModal("export")}>*/}
                  {/*<i className="fas fa-file-export"/> Export Charges*/}
                {/*</a>*/}
                <span>{toCurr(application.payments.reduce((acc, p) => p.amount + acc, 0))}</span>
              </CardHeader>
              <CardBody className="d-flex flex-column">
                {application.payments.map(p => {
                  return <ul key={p.id} className="list-unstyled">
                    <li>
                      <a href={`/payments/${p.id}`} target="_blank">Amount: <b>{toCurr(p.amount)}</b></a>
                    </li>
                    <li>
                      Received: {moment(p.inserted_at).format("MM/DD/YY")}
                    </li>
                    <ul>
                      {p.receipts.map(r => {
                        return <li key={r.id}>
                          <span>{r.account_name}: <b>{toCurr(r.amount)}</b></span>
                        </li>
                      })}
                    </ul>
                  </ul>
                })}
              </CardBody>
            </Card>
          </Col>
        </Row>
        <Row>
          <Col>
            <Card>
              <CardHeader>Rental Application Agreement</CardHeader>
              <CardBody>
                <p><b>These are the terms and conditions the applicant agreed to when submitting the application:</b></p>
                { application.terms_and_conditions.length > 0 &&
                  <div dangerouslySetInnerHTML={{__html: application.terms_and_conditions}} />
                }
                { application.terms_and_conditions.length == 0 &&
                  <p>None recorded</p>
                }
              </CardBody>
            </Card>
          </Col>
        </Row>
      </CardBody>
      {
        currentModal === "export" &&
        <ExportModal
          toggle={() => this.setCurrentModal("")}
          application={application}
        />
      }
    </Card>;
  }
}

export default Application;
