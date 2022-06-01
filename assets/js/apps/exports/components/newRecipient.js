import React from 'react';
import {Button, Input, Popover, PopoverBody, PopoverHeader} from "reactstrap";
import actions from '../actions';

class NewRecipient extends React.Component {
  state = {name: '', email: ''};

  change({target: {name, value}}) {
    this.setState({[name]: value});
  }

  toggle() {
    this.setState({popoverOpen: !this.state.popoverOpen});
  }

  saveRecipient() {
    const {name, email} = this.state;
    actions.createRecipient({name, email}).then(r => {
      this.props.parent.addRecipient(r.data.recipient);
      this.setState({popoverOpen: false, name: '', email: ''});
    })
  }

  render() {
    const {name, email, popoverOpen} = this.state;
    const toggle = this.toggle.bind(this);
    return <>
      <Button color="info" outline className="ml-2 px-2 d-flex" onClick={toggle} id="new-export-recipient-btn">
        <i style={{fontSize: '140%'}} className="fas fa-plus"/>
      </Button>
      <Popover className="popover-max" placement="top" isOpen={popoverOpen} target="new-export-recipient-btn"
               toggle={toggle}>
        <PopoverHeader>Add New Recipient</PopoverHeader>
        <PopoverBody>
          <div className="d-flex">
            <Input placeholder="Name" name="name" value={name} onChange={this.change.bind(this)}/>
            <Input type="email" placeholder="Email" className="ml-2" name="email" value={email}
                   onChange={this.change.bind(this)}/>
            <Button disabled={name.length < 3 || email.length < 3} className="ml-2"
                    color="success" onClick={this.saveRecipient.bind(this)}>
              <i className="fas fa-save"/>
            </Button>
          </div>
        </PopoverBody>
      </Popover>
    </>
  }
}

export default NewRecipient;