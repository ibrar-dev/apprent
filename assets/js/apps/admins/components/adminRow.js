import React from "react";
import {connect} from "react-redux";
import {Card, Col} from "reactstrap";
import {Link} from "react-router-dom";
import Password from "./password";
import actions from "../actions";
import icons from "../../../components/flatIcons";

class AdminRow extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      form: "",
    };
    this.imgRef = React.createRef();
  }

  fixAspect({target: img}) {
    const img2 = this.imgRef.current;
    const width = img.offsetWidth;
    const height = img.offsetHeight;
    const tallAndNarrow = width / height < 1;
    if (tallAndNarrow) img2.classList.add("tallAndNarrow");
    img2.classList.add("loaded");
  }

  toggleForm = (form) => (
    this.setState({form})
  )

  toggleCanResetPassword = () => {
    const {admin: {id, reset_pw}} = this.props;
    actions.updateAdmin({id, reset_pw: !reset_pw});
  }

  render() {
    const {admin:{id, name, email, roles, profile, reset_pw}} = this.props;
    const {form} = this.state;

    return (
      <Col md={4}>
        <Card style={{marginTop: 10, marginBottom: 10, height: 160, justifyContent: "center"}}>
          <div className="d-flex" style={{padding: 8}}>
            <div className="circle" style={{width: 80, height: 80, justifyContent: "center"}}>
              <img
                ref={this.imgRef}
                src={profile.image ? profile.image : icons.noUserImage}
                className="img-fluid"
                onLoad={this.fixAspect.bind(this)}
                aria-hidden
                alt="Tech profile photo"
              />
            </div>
            <div className="d-flex flex-column" style={{width: "60%", marginLeft: 19}}>
              <h6>{name}</h6>
              <h6>{email}</h6>
              <small className="text-muted">{roles.join(", ")}</small>
              <small
                className={`text-${reset_pw ? "success" : "warning"} cursor-pointer `}
                onClick={() => this.toggleCanResetPassword()}
                aria-hidden
              >
                {reset_pw ? "Able" : "Unable"}
                {" "}
                to reset their own password.
              </small>
            </div>
          </div>
          <div className="" style={{paddingLeft: 8}}>
            {form === "password" && <Password toggleForm={() => this.toggleForm("")} adminId={id}/>}
            {
              form === "" &&
              <>
                <a
                  onClick={() => this.toggleForm("password")}
                  className="m-0 btn btn-sm btn-outline-secondary"
                >
                  Change Password
                </a>
                <Link
                  to={`/admins/${id}`}
                  className="btn btn-sm btn-outline-success"
                  style={{marginLeft: 8}}
                >
                  View Admin
                </Link>
              </>
            }
          </div>
        </Card>
      </Col>
    )
  }
}

export default connect(({addresses, entities, activeAdmin}) => ({addresses, entities, activeAdmin}))(AdminRow)