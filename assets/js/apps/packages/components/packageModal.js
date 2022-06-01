import moment from "moment/moment";
import {connect} from "react-redux";
import React from "react";
import {Input, Button, Collapse,Row,Container, Modal, ModalHeader, ModalBody, Card, CardBody,Col,CardHeader,Alert,InputGroupAddon, InputGroupText} from "reactstrap";
import actions from "../actions";
import Select from 'react-select';


const reasonOp = ['Resident doesnt live here', 'Package never collected', 'Wrong address'];
const requiredStyles = {
    control: styles => ({ ...styles, width:'290px', height:'35px'})
};
class PackageModal extends React.Component {
   state = {
       ...this.props.currentPackage,
       ...this.props,
       packageIds : [this.props.currentPackage.id],
       tenantPackages: this.props.packages.filter(pack => (pack.unit_id == this.props.currentPackage.unit_id) ),
       enteredPin:''
     
   }
    submitPackage(){
        const opt = this.state.opt;
        const deliveredPackIds = this.state.packageIds;
        const packages = this.state.tenantPackages.filter(pack => deliveredPackIds.includes(pack.id))
        !opt ? packages.forEach(x => x.status = "Delivered") : packages.forEach(x => (x.status = "Delivered", x.reason = this.state.enteredPin));
        !opt ? (this.state.pin == this.state.enteredPin) ?
        (actions.updatePackages(packages), this.togglePackage()) :
            confirm("The pin you entered is incorrect") :
            (actions.updatePackages(packages), this.togglePackage())
    }

    optOut(){
        this.setState({...this.state, opt: !this.state.opt});
    }

    togglePackage(){
        this.state.returnToggle ? this.setState({...this.state, returnToggle: !this.state.returnToggle, packageToggle:!this.state.packageToggle})
            : this.setState({...this.state, packageToggle: !this.state.packageToggle })
    }

    toggleReturn(){
        this.state.packageToggle ? this.setState({...this.state, returnToggle: !this.state.returnToggle, packageToggle:!this.state.packageToggle})
            : this.setState({...this.state, returnToggle: !this.state.returnToggle })
    }

    changeReason(reason){
        this.setState({...this.state, reason: reason});
    }

    enteredPin(e){
        this.setState({...this.state, enteredPin: e.target.value});
    }

    deletePackage() {
        const deletedPackIds = this.state.packageIds;
        const packages = this.state.tenantPackages.filter(pack => deletedPackIds.includes(pack.id))
        packages.forEach(x => x.status = "Deleted");
        if (confirm("Delete this Package?")) {
           packages.forEach(x => actions.deletePackage(x))
        }
        window.location.reload();
    }

    changePackageIds({target: {value}}) {
       const packageIds = this.state.packageIds;
       const id = parseInt(value);
        packageIds.includes(id) ? packageIds.splice(packageIds.indexOf(id), 1) : packageIds.push(id);
        this.setState({packageIds: packageIds});

    }

    returnPackage(){
        const returnedPackIds = this.state.packageIds;
        const packages = this.state.tenantPackages.filter(pack => returnedPackIds.includes(pack.id));
        packages.forEach(x => {x.status = "Returned";
                               x.reason = this.state.reason.label;});
        packages.forEach(x => actions.updatePackage(x));
        this.toggleReturn();

    }

    holdPackage(){
        const returnedPackIds = this.state.packageIds;
        const packages = this.state.tenantPackages.filter(pack => returnedPackIds.includes(pack.id));
        packages.forEach(x => {x.status = "Hold";});
        packages.forEach(x => actions.updatePackage(x));
    }

  unholdPackage(){
    const returnedPackIds = this.state.packageIds;
    const packages = this.state.tenantPackages.filter(pack => returnedPackIds.includes(pack.id));
    packages.forEach(x => {x.status = "Pending";});
    packages.forEach(x => actions.updatePackage(x));
  }

  checkPackage( e ){
    const packageIds = this.state.packageIds;
    const id = parseInt(e.target.id);
    packageIds.includes(id) ? packageIds.splice(packageIds.indexOf(id), 1) : packageIds.push(id);
    this.setState({packageIds: packageIds});
  }

  render() {
       const {type,name,unit,tracking_number,status, carrier, condition,inserted_at,updated_at,toggle,packageToggle,opt,enteredPin,returnToggle,reason,packageIds,tenantPackages,admin} = this.state;
        const reasonOptions = reasonOp.map(op => {
            return {value: op, label: op};
        });
        const results = tenantPackages.filter(({id}) => packageIds.includes(id))
        const statuses = (results.map(x => x.status))
        const packageHoldStatus = statuses.every( x => x ==='Hold')
        const packagePendingStatus = statuses.every( x => x === 'Pending')

        return <Modal isOpen={true}  toggle={toggle} size='lg'>
            <ModalHeader toggle={toggle}>Package Details </ModalHeader>
            <ModalBody>
                <Row style={{minHeight: "390px"}}>
                    <Col>
                        <Row >
                        <Col >
                            <Row style ={{paddingLeft: "10px"}}>
                                 Recipients Name:
                            </Row>
                            <Row style ={{paddingLeft: "10px"}}>
                                 Recipients Unit:
                            </Row>
                            <Row style ={{paddingLeft: "10px"}}>
                                 Package Type:
                            </Row>
                            <Row style ={{paddingLeft: "10px"}}>
                                 Package Tracking No:
                            </Row>
                            <Row style ={{paddingLeft: "10px"}}>
                                 Package Status:
                            </Row>
                            <Row style ={{paddingLeft: "10px"}}>
                                 Package Carrier:
                            </Row>
                            <Row style ={{paddingLeft: "10px"}}>
                                 Package Condition:
                            </Row>
                            <Row style ={{paddingLeft: "10px"}}>
                                 Package Received:
                            </Row>
                            <Row style ={{paddingLeft: "10px"}}>
                                 Package Delivered:
                            </Row>
                            <Row style ={{paddingLeft: "10px"}}>
                                Admins Name:
                            </Row>

                        </Col>
                        <Col>
                            <Row style ={{paddingLeft: "10px"}}>
                                {name ? name :'not available'}
                            </Row>
                            <Row style ={{paddingLeft: "10px"}}>
                                {unit ? unit : ' not available'}
                            </Row>
                            <Row style ={{paddingLeft: "10px"}}>
                                {type ? type : ' not available'}
                            </Row>
                            <Row style ={{paddingLeft: "10px"}}>
                                {tracking_number ? tracking_number : 'not available'}
                            </Row>
                            <Row style ={{paddingLeft: "10px"}}>
                                {status ? status : 'not available'}
                            </Row>
                            <Row style ={{paddingLeft: "10px"}}>
                                {carrier ? carrier : 'not available'}
                            </Row>
                            <Row style ={{paddingLeft: "10px"}}>
                                {condition ? condition : 'not available'}
                            </Row>
                            <Row style ={{paddingLeft: "10px"}}>
                                {moment(inserted_at).format('MMMM Do YYYY') }
                            </Row>
                            <Row style ={{paddingLeft: "10px"}}>
                                {status == 'Delivered' ? moment(updated_at).format('MMMM Do YYYY, h:mm a') : 'not available'}
                            </Row>
                            <Row style ={{paddingLeft: "10px"}}>
                                {admin ? admin : 'not available'}
                            </Row>

                        </Col>
                        </Row>
                        <div style = {{marginTop : "40px"}}>
                            <small className="text-muted"> {tenantPackages.filter(x => x.status == "Pending" && packageIds.includes(x.id)).length} of {tenantPackages.filter(x => x.status == "Pending" ).length} Pending package(s) selected</small> <br/>
                            <small className="text-muted"> {tenantPackages.filter(x => x.status == "Delivered" && packageIds.includes(x.id)).length} of {tenantPackages.filter(x => x.status == "Delivered" ).length} Delivered package(s) selected</small> <br/>
                            <small className="text-muted"> {tenantPackages.filter(x => x.status == "Undeliverable" && packageIds.includes(x.id)).length} of {tenantPackages.filter(x => x.status == "Undeliverable" ).length} Undelivered package(s) selected</small><br/>
                            <small className="text-muted"> {tenantPackages.filter(x => x.status == "Hold" && packageIds.includes(x.id)).length} of {tenantPackages.filter(x => x.status == "Hold" ).length} Held package(s) selected</small>
                        </div>
                        <div className="d-flex" style={{position: "absolute", bottom: "0"}}>
                            {(status != 'delivered' && status != 'returned') ?
                                <Button outline color="info" className="mr-3"
                                        onClick={this.toggleReturn.bind(this)}
                                        disabled={tenantPackages.some(x => x.status != 'Undeliverable' && packageIds.includes(x.id)) || packageIds.length == 0}
                                >Return</Button>
                                : ''}
                            {(status != 'delivered' && status != 'returned') ?
                                <Button outline color="success" className="mr-3"
                                        onClick={this.togglePackage.bind(this)}
                                        disabled={tenantPackages.some(x => (x.status != "Hold" && x.status != 'Pending') && packageIds.includes(x.id)) || packageIds.length == 0}
                                >Pick Up</Button> : ''}


                          {packagePendingStatus && <Button
                            outline color="primary" className="mr-3"
                            onClick={this.holdPackage.bind(this)}
                          >Hold
                          </Button>}
                          {!packagePendingStatus && <Button
                            outline color="primary" className="mr-3"
                            onClick={this.unholdPackage.bind(this)}
                            disabled={tenantPackages.some(x => x.status != 'Hold' && packageIds.includes(x.id)) || packageIds.length == 0}>
                            Unhold
                          </Button>}

                          <Button outline color="danger" className="mr-3"
                                    onClick={this.deletePackage.bind(this) || packageIds.length == 0}>Delete</Button>
                        </div>

                    </Col>
                    <Col>
                        <Card>
                            <CardHeader >All Packages For This Tenant</CardHeader>
                              <CardBody style = {{overflowY : "scroll", maxHeight: "230px"}} onClick={this.checkPackage.bind(this)} >
                                {tenantPackages.map(pack =>
                                    (<Alert key= {pack.id} color={pack.status == "Delivered" ? "success" : pack.status == "Returned" ? "primary" : pack.status == "Pending" ? "secondary" : "danger"} id ={pack.id}>
                                      <Row id ={pack.id} >
                                        <InputGroupAddon addonType="prepend" id ={pack.id} >
                                            <InputGroupText id ={pack.id}>
                                                <Input addon type="checkbox"
                                                       aria-label="Checkbox for following text input"
                                                       id={pack.id}
                                                       checked={packageIds.includes(pack.id)}
                                                       readOnly
                                                />
                                            </InputGroupText>
                                        </InputGroupAddon >
                                        <Col id = {pack.id}>
                                          <Row id = {pack.id}>
                                                {pack.carrier} <br/>
                                                {pack.status}
                                          </Row>
                                        </Col >
                                        <Col id = {pack.id}>
                                          <Row id = {pack.id}>
                                                {moment(pack.inserted_at).format('MMMM Do YYYY')}
                                          </Row>
                                        </Col>
                                    </Row></Alert>)
                                )}
                              </CardBody>
                        </Card>
                        <Container style={{  }}>
                            <Collapse isOpen={packageToggle && !(tenantPackages.some(x =>(x.status != "Hold" && x.status != 'Pending') && packageIds.includes(x.id)) || packageIds.length == 0)}>
                                <Row>
                                    {!opt ? <b>Enter pin to submit</b> :
                                        <b>Enter reason for opting out then submit</b>}
                                </Row>
                                <Row style={{paddingBottom: "10px"}}>
                                    {!opt ?
                                        <Input name="enteredPin" value={enteredPin}
                                               onChange={this.enteredPin.bind(this)}
                                               style={{maxWidth: "290px"}}/> :
                                        <Input type="textarea" name="enteredPin" value={enteredPin}
                                               onChange={this.enteredPin.bind(this)} style={{maxWidth: "290px"}}/>}
                                </Row>
                                <Row>
                                    <Button color="success" className="mr-3"
                                            onClick={this.submitPackage.bind(this)}
                                            disabled={!opt ? enteredPin.length != 4 : enteredPin.length < 1}>Submit</Button>
                                    <Button outline color="info" className="mr-3"
                                            onClick={this.optOut.bind(this)
                                            }>Opt Out</Button>
                                </Row>
                            </Collapse>
                        </Container>

                        <Container style={{}}>
                            <Collapse isOpen={returnToggle && !(tenantPackages.some(x => x.status != 'Undeliverable' && packageIds.includes(x.id)))}>
                                <Row>
                                    <b>Select a reason for return</b>
                                </Row>
                                <Row style={{paddingBottom: "10px"}}>
                                    <Select value={reason}
                                            multi={false}
                                            options={reasonOptions}
                                            onChange={this.changeReason.bind(this)}
                                            styles={requiredStyles}/>
                                </Row>
                                <Row>
                                    <Button color="success" className="mr-3"
                                            onClick={this.returnPackage.bind(this)} disabled={false}>Submit</Button>
                                </Row>
                            </Collapse>
                        </Container>

                    </Col>
                </Row>
            </ModalBody>
        </Modal>
    }
}
export default connect(pack => {
    return (pack)
})(PackageModal)