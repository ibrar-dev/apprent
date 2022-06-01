import React from 'react';
import {Button, Input, InputGroup, InputGroupAddon, Popover, PopoverBody, PopoverHeader} from "reactstrap";
import actions from '../actions';

class NewCategory extends React.Component {
  state = {name: ''};

  change({target: {name, value}}) {
    this.setState({[name]: value});
  }

  toggle() {
    this.setState({popoverOpen: !this.state.popoverOpen});
  }

  saveCategory() {
    const {name} = this.state;
    actions.createCategory({name}).then(r => {
      this.props.parent.addCategory(r.data.category);
      this.setState({popoverOpen: false, name: ''});
    })
  }

  render() {
    const {name, popoverOpen} = this.state;
    const toggle = this.toggle.bind(this);
    return <>
      <Button title="New Category" color="info" outline className="ml-2 px-2 d-flex" onClick={toggle}
              id="new-export-category-btn">
        <i style={{fontSize: '140%'}} className="fas fa-plus"/>
      </Button>
      <Popover placement="top" isOpen={popoverOpen} target="new-export-category-btn" toggle={toggle}>
        <PopoverHeader>Add New Category</PopoverHeader>
        <PopoverBody>
          <InputGroup>
            <Input name="name" value={name} onChange={this.change.bind(this)}/>
            <InputGroupAddon addonType="append">
              <Button disabled={name.length < 3} color="success" onClick={this.saveCategory.bind(this)}>
                <i className="fas fa-save"/>
              </Button>
            </InputGroupAddon>
          </InputGroup>
        </PopoverBody>
      </Popover>
    </>
  }
}

export default NewCategory;