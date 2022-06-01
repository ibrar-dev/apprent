import React from "react";
import {Input, Button, Popover, PopoverBody, Row, Container} from "reactstrap";
import actions from "../actions";
import moment from 'moment';
import Select from 'react-select';
import PackageModal from './packageModal'
import Image from '../images/menu.svg';
import Img0 from '../images/amazonLogo.png';
import Img1 from '../images/fedex.png';
import Img2 from '../images/ups.png';
import Img3 from '../images/usps.png';
import Img4 from '../images/dhl.png';
import Img5 from '../images/laserShip.png';
import Flower from '../images/lotus.svg';
import Mail from '../images/envelope.svg';
import Mail2 from '../images/mail.svg';
import Ten from '../images/checked.svg';
import NotTen from '../images/cancel.svg';
import color from 'color';

const mailLogo = {Amazon: Img0, FedEx: Img1, UPS: Img2, USPS: Img3, LaserShip: Img5, DHL: Img4, Florist: Flower};
const reasonOp = ['Resident doesnt live here', 'Package never collected', 'Wrong address'];
const requiredStyles = {
  control: styles => ({...styles, width: '180px', height: '35px'})
};
const colorPalete = {
  Undeliverable: "#ffa2a296",
  Delivered: "#d1e3d5",
  Returned: "#cce5ff",
  Pending: "white",
  Hold: "white"
};
const colorPaleteHover = {Undeliverable: "#e6767696", Delivered: "#B8D2BB", Returned: "#a2c5ea"};

class Package extends React.Component {
  state = {
    ...this.props.pack,
    edit: false,
    invalidAttributes: false,
    enteredPin: '',
    reason: ''
  };

  componentWillReceiveProps(props) {
    this.setState({...props.pack});
  }

  updatePackage() {
    const {unit, status, carrier} = this.state;
    if (unit === '' || carrier === '' || status === '') {
      this.setState({invalidAttributes: true});
    } else {
      actions.updatePackage(this.state);
    }
  }

  togglePackage() {
    this.state.returnToggle ? this.setState({
        ...this.state,
        returnToggle: !this.state.returnToggle,
        packageToggle: !this.state.packageToggle
      })
      : this.setState({...this.state, packageToggle: !this.state.packageToggle})
  }

  togglePopover(e) {
    e.stopPropagation();
    this.setState({...this.state, popoverOpen: !this.state.popoverOpen});
  }

  togglePackageModal() {
    this.setState({...this.state, packageModal: !this.state.packageModal});
  }

  toggleReturn() {
    this.state.packageToggle ? this.setState({
        ...this.state,
        returnToggle: !this.state.returnToggle,
        packageToggle: !this.state.packageToggle
      })
      : this.setState({...this.state, returnToggle: !this.state.returnToggle})
  }

  optOut() {
    this.setState({...this.state, opt: !this.state.opt});
  }

  change({target}) {
    this.setState({...this.state, [target.name]: target.value});
  }

  changeStatus(status) {
    this.setState({...this.state, status: status.value});
  }

  changeCarrier(carrier) {
    this.setState({...this.state, carrier: carrier});
  }

  changeReason(reason) {
    this.setState({...this.state, reason: reason});
  }

  deletePackage() {
    if (confirm("Delete this Package?")) {
      actions.deletePackage(this.props.pack);
    }
    window.location.reload();
  }

  enteredPin(e) {
    this.setState({...this.state, enteredPin: e.target.value});
  }

  holdPackage() {
    const pack = ({...this.state, status: "Hold"})
    actions.updatePackage(pack)
  }

  unholdPackage() {
    const pack = ({...this.state, status: "Unhold"})
    actions.updatePackage(pack)
  }

  submitPackage() {
    const opt = this.state.opt
    const deliveredPack = !opt ? {...this.state, status: "Delivered"} : {
      ...this.state,
      status: "Delivered",
      reason: this.state.enteredPin
    }
    !opt ? (this.state.pin == this.state.enteredPin) ?
      (actions.updatePackage(deliveredPack), this.togglePackage()) :
      confirm("The pin you entered is incorrect") :
      (actions.updatePackage(deliveredPack), this.togglePackage())

  }

  returnPackage() {
    const returnPack = {...this.state, status: "Returned", reason: this.state.reason.label};
    actions.updatePackage(returnPack), this.toggleReturn();
  }

  render() {
    const {name, unit, status, carrier, inserted_at, updated_at, popoverOpen, id, enteredPin, packageToggle, returnToggle, opt, reason, packageModal, email, current_tenant} = this.state;
    const reasonOptions = reasonOp.map(op => {
      return {value: op, label: op};
    });
    const rowStyles = {
      backgroundColor: color(colorPalete[status]),
      ':hover': {
        backgroundColor: color(colorPaleteHover[status])
      }
    };

    return <React.Fragment>
      <tr className="link-row" onClick={this.togglePackageModal.bind(this)} style={rowStyles} key={id}>
        <td>
          <p className="m-0">
            {current_tenant ? <img src={Ten} height="20" color="white"/> :
              <img src={NotTen} height="20" color="white"/>} {email ? <img src={Mail2} height="20" color="white"/> :
            <img src={Mail} height="20" color="white"/>} {name}
          </p>
        </td>
        <td>
          <p className="m-0">
            {this.props.pack.property}-{unit}
          </p>
        </td>
        <td style={{minWidth: '150px'}}>
          {status}
        </td>
        <td>
          {(mailLogo[carrier] ? <img src={mailLogo[carrier]} height="20" color="white"/> : carrier)}
        </td>
        <td>
          <p className="m-0">
            {moment(inserted_at).format('MMMM Do YYYY')}
          </p>
        </td>
        <td>
          <p className="m-0">
            {status == 'Delivered' ? moment(updated_at).format('MMMM Do YYYY, h:mm:ss a') : ''}
          </p>
        </td>
        <td>
          <Button id={`package-${id}`} onClick={this.togglePopover.bind(this)}
                  style={{backgroundColor: "#fff", borderColor: "#fff"}}>
            <img src={Image} height="15" width="15" color="white"/>
          </Button>
          <Popover placement="left" target={`package-${id}`} isOpen={popoverOpen} onClick={e => e.stopPropagation()} onMouseEnter={e => e.stopPropagation()}>
            <PopoverBody>
              <div className="d-flex">
                {(status == 'Undeliverable') ?
                  <Button outline color="info" className="mr-3" onClick={this.toggleReturn.bind(this)}>Return</Button>
                  : ''}
                {(status == 'Pending') ?
                  <React.Fragment>
                    <Button outline color="success" className="mr-3" onClick={this.togglePackage.bind(this)}>Pick
                      Up</Button>
                    <Button outline color="secondary" className="mr-3"
                            onClick={this.holdPackage.bind(this)}>Hold</Button> </React.Fragment> : ''}
                {(status == 'Hold') ?
                  <React.Fragment>
                    <Button outline color="secondary" className="mr-3"
                            onClick={this.unholdPackage.bind(this)}>Unhold</Button> </React.Fragment> : ''}
                <Button outline color="danger" className="mr-3" onClick={this.deletePackage.bind(this)}>Delete</Button>
              </div>
              {packageToggle && <Container style={{paddingTop: "20px"}}>
                <Row>
                  {!opt ? <b>Enter pin to submit</b> :
                    <b>Enter reason for opting out then submit</b>}
                </Row>
                <Row style={{paddingBottom: "10px"}}>
                  {!opt ? <Input name="enteredPin" value={enteredPin} onChange={this.enteredPin.bind(this)}/> :
                    <Input type="textarea" name="enteredPin" value={enteredPin} onChange={this.enteredPin.bind(this)}/>}
                </Row>
                <Row>
                  <Button color="success" className="mr-3"
                          onClick={this.submitPackage.bind(this)}
                          disabled={!opt ? enteredPin.length != 4 : enteredPin.length < 1}>Submit</Button>
                  <Button outline color="info" className="mr-3"
                          onClick={this.optOut.bind(this)}>{opt ? "Enter Pin" : "Opt Out"}</Button>
                </Row>
              </Container>
              }
              {returnToggle && <Container style={{paddingTop: "20px"}}>
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
              </Container>
              }
            </PopoverBody>
          </Popover>
        </td>
      </tr>
      {packageModal && <PackageModal
        currentPackage={this.props.pack}
        packages={this.props.packages}
        toggle={this.togglePackageModal.bind(this)}
      />}
    </React.Fragment>
  }
}

export default Package