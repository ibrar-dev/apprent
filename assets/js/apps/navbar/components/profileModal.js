import React, {Component} from 'react';
import {Modal, ModalHeader, Input, Col, Row, Button, Container} from 'reactstrap';
import actions from '../actions';
import Uploader from '../../../components/uploader';
import icons from '../../../components/flatIcons';

class ProfileModal extends Component {
  state = {...this.props.admin.profile};

  handleChange(e) {
    this.setState({...this.state, [e.target.name]: e.target.value})
  }

  edit() {
    this.setState({edit: !this.state.edit});
  }

  save() {
    const {admin} = this.props;
    const {bio, image, title, active} = this.state;
    const profile = {admin_id: admin.id, id: admin.profile.id, title, active, bio};
    image.upload().then(() => {
      if (image.uuid) profile.image = {uuid: image.uuid};
      actions.updateProfile(profile);
    });
    this.setState({...this.state, edit: !this.state.edit});
  }

  updateImage(image) {
    this.setState({...this.state, image});
  }

  render() {
    const {admin, toggle} = this.props;
    const {edit, bio, title} = this.state;
    return <Modal isOpen={true} toggle={toggle.bind(this)}>
      <ModalHeader style={{width: "100%"}} toggle={toggle.bind(this)}>
        {admin.name}'s Profile
      </ModalHeader>
      <Container>
        <Row>
          <Col sm="4" className="text-center" style={{padding: 10, borderRight: "1px solid #e0e0e0", height: 170}}>
            {edit ?
              <Uploader containerClass="h-100 align-items-center d-flex justify-content-center"
                        label="Select Image" onChange={this.updateImage.bind(this)}/> :
              <img src={admin.profile.image ? admin.profile.image : icons.noUserImage}
                   style={{maxWidth: '100%', maxHeight: 150}}/>
            }
          </Col>
          <Col sm="8" className="d-flex flex-column">
            <Row>
              <Col sm="2" className="d-flex align-items-center">
                <h6 style={{color: "#808080"}}>
                  Title
                </h6>
              </Col>
              <Col sm="10">
                <Input value={title || ''} disabled={!edit} name="title" onChange={this.handleChange.bind(this)}
                       style={{marginTop: 5}}/>
              </Col>
            </Row>
            <Row>
              <Col sm="2" className="d-flex align-items-center">
                <h6 style={{color: "#808080"}}>
                  Bio
                </h6>
              </Col>
              <Col sm="10">
                <Input value={bio || ''} disabled={!edit} type="textarea" name="bio"
                       onChange={this.handleChange.bind(this)} style={{marginTop: 5}}/>
              </Col>
            </Row>

            <div className="mb-2 align-self-end mt-auto">
              <Button size="sm" color="danger" outline
                      onClick={this.edit.bind(this)}> {edit ? "Cancel" : "Edit"}</Button>
              {edit &&
              <Button color="success" outline className="ml-2" size="sm" onClick={this.save.bind(this)}> Save </Button>}
            </div>
          </Col>
        </Row>
      </Container>
    </Modal>
  }
}

export default ProfileModal;