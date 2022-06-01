import React from "react";
import {connect} from "react-redux";
import {withRouter} from "react-router-dom";
import {Card, Row, Col, Container} from "reactstrap";
import icons from "../../../../components/flatIcons";
import ProfileModal from "../profileModal";

//TODO CLEANUP
class Info extends React.Component {
  constructor(props) {
    super(props);
    this.imgRef = React.createRef();
    this.state = {
      newPW: "",
      showEntities: false,
      showPWReset: false,
      validated: false,
      selectedRoles: [],
      selectedEntities: [],
    };
  }

  static getDerivedStateFromProps(props, state) {
    const {selectedRoles, selectedEntities} = state;
    const {activeAdmin: {roles, entity_ids}} = props;
    if ((roles !== selectedRoles) || (entity_ids !== selectedEntities)) {
      return {
        selectedRoles: roles,
        selectedEntities: entity_ids,
      };
    }
    return null;
  }


  toggleEditAdmin = () => {
    this.setState({editAdmin: !this.state.editAdmin});
  }

  fixAspect({target: img}) {
    const img2 = this.imgRef.current;
    const width = img.offsetWidth;
    const height = img.offsetHeight;
    const tallAndNarrow = width / height < 1;
    if (tallAndNarrow) img2.classList.add("tallAndNarrow");
    img2.classList.add("loaded");
  }

  render() {
    const {username, name, email, roles, profile} = this.props.activeAdmin;
    const {activeAdmin} = this.props;
    const {editAdmin} = this.state;
    if (Object.keys(activeAdmin).length === 0) return null;
    return (
      <Container>
        {editAdmin && <ProfileModal toggleEditAdmin={() => this.toggleEditAdmin(this)}/>}
          <div style={{padding: 30, paddingLeft: 30, paddingRight: 30}}>
            <Row className="d-flex justify-content-between">
              <div className="d-flex">
                <h4 style={{color: "#97a4af"}}>Admin</h4>
                  {
                    profile.active
                      ? (
                        <span
                          className="badge badge-pill badge-success align-self-center"
                          style={{marginBottom: 7, marginLeft: 10}}
                        >
                          Profile Active
                        </span>)
                      : (
                        <span
                          className="badge badge-pill badge-danger align-self-center"
                          style={{marginBottom: 7, marginLeft: 10}}
                        >
                          Profile Inactive
                        </span>
                      )
                  }
                </div>
                <i
                  className="fas fa-edit"
                  style={{fontSize: 23, color: "#3a3c42", cursor: "pointer"}}
                  onClick={() => this.toggleEditAdmin()}
                />
              </Row>
              <div className="d-flex">
                <Col md={4} style={{paddingLeft: 0}}>
                  <div
                    className="circle"
                    style={{
                      width: 120,
                      height: 120,
                      justifyContent: "center",
                      alignSelf: "center",
                      marginBottom: 13,
                    }}
                  >
                    <img
                      src={profile.image ? profile.image : icons.noUserImage}
                      ref={this.imgRef}
                      className="img-fluid" onLoad={this.fixAspect.bind(this)}
                      alt="Admin profile photo"
                    />
                  </div>
                </Col>
                <Col>
                <Row>
                  <Col>
                    <Row><h6 style={{color: "#525e69", fontWeight: "bold"}}>Name</h6></Row>
                    <Row><h6 style={{color: "#525e69", fontWeight: "bold"}}>Username</h6></Row>
                    <Row><h6 style={{color: "#525e69", fontWeight: "bold"}}>Email</h6></Row>
                    <Row><h6 style={{color: "#525e69", fontWeight: "bold"}}>Title</h6></Row>
                  </Col>
                  <Col>
                    <Row><h6 style={{color: "#525e69"}}>{name}</h6></Row>
                    <Row><h6 style={{color: "#525e69"}}>{username}</h6></Row>
                    <Row><h6 style={{color: "#525e69"}}>{email}</h6></Row>
                    <Row>
                      <h6 style={{color: "#525e69"}}>
                        {((profile.title == null) || (profile.title === "null")) ? "N/A" : profile.title}
                      </h6>
                    </Row>
                  </Col>
                </Row>
                <Row>
                  <small className="text-muted">
                    {roles.map((x, i) => (i + 1) === roles.length ? x : `${x}, `)}
                  </small>
                </Row>
              </Col>
            </div>
            <div style={{flexDirection: "column"}}>
            <h6 style={{color: "#525e69", fontWeight: "bold", alignSelf: "center", marginTop: 15}}>
              Biography
            </h6>
            <p>{((profile.bio == null) || (profile.bio === "null")) ? "N/A" : profile.bio}</p>
          </div>
        </div>
      </Container>
    );
  }
}

export default withRouter(connect(({addresses, entities, activeAdmin, actions}) => {
  return {addresses, entities, activeAdmin, actions};
})(Info));
