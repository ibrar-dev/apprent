import React, {Component} from 'react';
import {connect} from 'react-redux';
import {Modal, ModalHeader, Input, Col, Row, Button, ModalBody, ButtonGroup} from 'reactstrap';
import actions from '../actions';
import DropZone from '../dropzone';
import icons from '../../../components/flatIcons';

class ProfileModal extends Component {
  state = {
    active: this.props.activeAdmin.profile.active,
    title: this.props.activeAdmin.profile.title,
    bio: this.props.activeAdmin.profile.bio,
    image: this.props.activeAdmin.profile.image,
    name: this.props.activeAdmin.name,
    username: this.props.activeAdmin.username,
    email: this.props.activeAdmin.email
  };

  updateActive(state) {
    this.setState({active: state});
  }

  handleChange(e) {
    this.setState({...this.state, [e.target.name]: e.target.value})
  }

  edit() {
    this.setState({
      ...this.state,
      edit: !this.state.edit,
      active: this.props.activeAdmin.profile.active,
      title: this.props.activeAdmin.profile.title,
      bio: this.props.activeAdmin.profile.bio,
      image: this.props.activeAdmin.profile.image
    });
  }

  save() {
    const profile1 = {
      title: this.state.title,
      active: this.state.active,
      bio: this.state.bio,
      admin_id: this.props.activeAdmin.id,
      id: this.props.activeAdmin.profile.id,
      image: this.state.image
    };
    const {activeAdmin} = this.props;
    const {active, bio, image, title, name, username, email} = this.state;
    const admin_profile = new FormData();
    actions.updateAdmin({id: activeAdmin.id, name: name, username: username, email: email});
    admin_profile.append('admin_profile[active]', active || false);
    admin_profile.append('admin_profile[bio]', bio);
    admin_profile.append('admin_profile[title]', title);
    image && admin_profile.append('admin_profile[image]', image);
    admin_profile.append('admin_profile[admin_id]', activeAdmin.id);
    actions.updateProfile(admin_profile, profile1.id);
    this.setState({...this.state, edit: !this.state.edit});
  }

  updateImage(file) {
    this.setState({...this.state, image: file});
  }

  render() {
    const {activeAdmin, toggleEditAdmin} = this.props;
    const {edit, bio, active, title, name, username, email} = this.state;
    return <Modal isOpen={true} toggle={toggleEditAdmin.bind(this)}>
      <ModalHeader style={{width: "100%"}} toggle={toggleEditAdmin.bind(this)}>
        Admin Profile
      </ModalHeader>
      <ModalBody>
        <Row>
          <Col sm="4" style={{padding: "10px", borderRight: "1px solid #e0e0e0"}}>
            <Row className="d-flex justify-content-center"
                 style={{marginBottom: 20, height: "50%", padding: "10%", paddingTop: 0}}>
              {edit ? <DropZone onChange={(file) => this.updateImage(file)}/> :
                <img src={activeAdmin.profile.image ? activeAdmin.profile.image : icons.noUserImage} height="150"
                     width="150"/>
              }
            </Row>
            <Row className="d-flex justify-content-center">
              <ButtonGroup>
                <Button disabled={!edit} style={(active && !edit) ? {backgroundColor: "#eceff0"} : {}} active={active}
                        onClick={this.updateActive.bind(this, true)} outline>Active</Button>
                <Button disabled={!edit} style={(!active && !edit) ? {backgroundColor: "#eceff0"} : {}} active={!active}
                        onClick={this.updateActive.bind(this, false)} outline>Inactive</Button>
              </ButtonGroup>
              {/*<Checkbox style={{borderColor:"#475f78"}} disabled={!edit} checked={active} onChange={this.updateActive.bind(this)} color={`primary`}/>*/}
            </Row>
          </Col>
          <Col sm="8">
            <Row style={{marginTop: "5px"}}>
              <Col sm="3" className="d-flex align-items-center">
                <h6 style={{color: "#808080"}}>
                  Name
                </h6>
              </Col>
              <Col sm="9">
                <Input value={name ? name : ""} disabled={!edit} name="name" onChange={this.handleChange.bind(this)}
                       style={{marginTop: "5px"}}/>
              </Col>
            </Row>
            <Row style={{marginTop: "5px"}}>
              <Col sm="3" className="d-flex align-items-center">
                <h6 style={{color: "#808080"}}>
                  Username
                </h6>
              </Col>
              <Col sm="9">
                <Input value={username ? username : ""} disabled={!edit} name="username"
                       onChange={this.handleChange.bind(this)} style={{marginTop: "5px"}}/>
              </Col>
            </Row>
            <Row style={{marginTop: "5px"}}>
              <Col sm="3" className="d-flex align-items-center">
                <h6 style={{color: "#808080"}}>
                  Email
                </h6>
              </Col>
              <Col sm="9">
                <Input value={email ? email : ""} disabled={!edit} name="email" onChange={this.handleChange.bind(this)}
                       style={{marginTop: "5px"}}/>
              </Col>
            </Row>
            <Row style={{marginTop: "5px"}}>
              <Col sm="3" className="d-flex align-items-center">
                <h6 style={{color: "#808080"}}>
                  Title
                </h6>
              </Col>
              <Col sm="9">
                <Input value={title ? title : ""} disabled={!edit} name="title" onChange={this.handleChange.bind(this)}
                       style={{marginTop: "5px"}}/>
              </Col>
            </Row>
            <Row style={{marginTop: "5px", marginBottom: 15}}>
              <Col sm="3" className="d-flex align-items-center">
                <h6 style={{color: "#808080"}}>
                  Bio
                </h6>
              </Col>
              <Col sm="9">
                <Input value={bio ? bio : ""} disabled={!edit} type="textarea" name="bio"
                       onChange={this.handleChange.bind(this)} style={{marginTop: "5px"}}/>
              </Col>
            </Row>

            {edit &&
            <Button color="success" outline size="sm" style={{float: "right", marginTop: "5px", marginBottom: "5px"}}
                    onClick={this.save.bind(this)}> Save </Button>}
            <Button size="sm" color="danger" outline style={{float: "right", margin: "5px"}}
                    onClick={this.edit.bind(this)}> {edit ? "Cancel" : "Edit"}</Button>

          </Col>
        </Row>
      </ModalBody>
    </Modal>
  }
}

export default connect(({activeAdmin}) => {
  return {activeAdmin}
})(ProfileModal);