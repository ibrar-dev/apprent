import React from 'react';
import {Button, PopoverHeader, PopoverBody, Popover, InputGroup, InputGroupAddon, Input} from 'reactstrap';
import actions from '../../actions';

class SocialButton extends React.Component {
  constructor(props) {
    super(props);
    this.state = {link: props.property.social[props.type] || ''};
  }

  edit() {
    this.setState({edit: !this.state.edit});
  }

  changeLink(e) {
    this.setState({link: e.target.value});
  }

  save() {
    const {property, type} = this.props;
    const social = {...property.social, [type]: this.state.link};
    actions.updateProperty({id: property.id, social}).then(this.edit.bind(this));
  }

  render() {
    const {link, edit} = this.state;
    const {type, property} = this.props;
    const id = `social-btn-${type}-${property.id}`;
    return <React.Fragment>
      <Button id={id} className="w-25"
              color={link ? 'outline-dark' : 'outline-danger'}
              onClick={this.edit.bind(this)}>
        <span className={`fab fa-${type}`}/>
      </Button>
      <Popover target={id}
               placement="top"
               className="mw-100"
               style={{width: '500px', maxWidth: '500px'}}
               isOpen={edit}>
        <PopoverHeader>
          Edit Link
        </PopoverHeader>
        <PopoverBody>
          <InputGroup>
            <Input value={link} onChange={this.changeLink.bind(this)}/>
            <InputGroupAddon addonType="append">
              <Button color="info" onClick={this.save.bind(this)}>
                <i className="fas fa-save"/>
              </Button>
            </InputGroupAddon>
          </InputGroup>
        </PopoverBody>
      </Popover>
    </React.Fragment>;
  }
}

export default SocialButton;