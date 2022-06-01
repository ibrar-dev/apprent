import React, {Component} from "react";
import moment from "moment";
import "moment-timezone";
import {List, Pagination} from "antd";
import {
  Table, Input, Button, InputGroup, InputGroupAddon, Row, Col, ButtonGroup,
} from "reactstrap";
import Switch from "../../../../../components/switch";
import confirmation from "../../../../../components/confirmationModal";
import actions from "../../../actions";
import LoginDetail from "./loginDetail";

class AccountDetails extends Component {
  constructor(props) {
    super(props);
    this.state = {
      password: "",
      username: props.account.username,
      editAutopay: false,
    };

    this.change = this.change.bind(this);
    this.updateAccount = this.updateAccount.bind(this);
    this.savePassword = this.savePassword.bind(this);
    this.sendResetEmail = this.sendResetEmail.bind(this);
    this.sendWelcomeEmail = this.sendWelcomeEmail.bind(this);
    this.toggleEditAutopay = this.toggleEditAutopay.bind(this);
    this.changeAutoPay = this.changeAutopay.bind(this);
  }

  componentWillMount() {
    const {account: {autopay}} = this.props;
    this.setState({...this.state, autopay});
  }

  change({target: {name, value}}) {
    this.setState({[name]: value});
  }

  updateAccount({target: {name, value}}) {
    const {account} = this.props;
    actions.updateAccount({id: account.id, [name]: value});
  }

  savePassword() {
    confirmation("Change this user's password?").then(() => {
      const {account} = this.props;
      const {password} = this.state;
      actions.updateAccount({...account, password}).then(() => this.setState({password: ""}));
    });
  }

  sendResetEmail() {
    actions.sendResetPasswordEmail(this.props.email).then(() => {
      alert("Reset password email sent!");
    });
  }

  sendWelcomeEmail() {
    confirmation("Re-sending the welcome email will reset the resident's password. Are you sure you would like to send the welcome email?").then(() => {
      actions.sendWelcomeEmail(this.props.account.id).then(() => {
        alert("Welcome email sent to resident.");
      });
    });
  }

  toggleEditAutopay() {
    this.setState({...this.state, editAutopay: !this.state.editAutopay});
  }

  changeAutopay({target: {name, value}}) {
    const {autopay} = this.state;
    autopay[name] = value;
    this.setState({...this.state, autopay});
  }

  unique(records) {
    return records.reduce((uniques, record) => {
      if (uniques.some((item) => item.id === record.id)) return uniques;
      return [...uniques, record];
    }, []);
  }

  sortById(records) {
    return records.sort((a, b) => b.id - a.id);
  }

  renderLogin(login) {
    return (
      <LoginDetail
        key={login.ts}
        timestamp={login.ts}
        type={login.type}
        login_metadata={login.login_metadata}
      />
    );
  }

  renderLogins(logins) {
    if (logins.length === 0) return "Never";
    const uniqueLogins = this.unique(logins);
    return <List
      dataSource={uniqueLogins}
      renderItem={item => this.renderLogin(item)}
      pagination
      />;
  }

  render() {
    const {sortedLocks, account = {}} = this.props;
    const {password_resets = []} = account;
    const [lastPasswordReset] = this.sortById(password_resets);
    const {password, username} = this.state;

    return (
      <Table className="m-0">
        <tbody>
          <tr>
            <th className="align-middle border-top-0">Username</th>
            <td className="border-top-0">
              <Row>
                <Col sm={8}>
                  <InputGroup>
                    <Input value={username} name="username" onChange={this.change} />
                    <InputGroupAddon addonType="append">
                      <Button
                        outline
                        color="success"
                        disabled={account.username.length < 5}
                        onClick={() => this.updateAccount({target: {name: "username", value: username}})}
                      >
                        Save
                      </Button>
                    </InputGroupAddon>
                  </InputGroup>
                </Col>
              </Row>
            </td>
          </tr>
          <tr>
            <th className="align-middle">New Password</th>
            <td>
              <Row>
                <Col sm={8}>
                  <InputGroup>
                    <Input value={password} name="password" onChange={this.change} />
                    <InputGroupAddon addonType="append">
                      <Button outline color="success" disabled={password.length < 8} onClick={this.savePassword}>
                        Save
                      </Button>
                    </InputGroupAddon>
                  </InputGroup>
                  {
                    lastPasswordReset
                      ? (
                        <span>
                          Last Password Reset:
                          {" "}
                          {moment.utc(lastPasswordReset.inserted_at).local().format("MM/DD/YYYY hh:mmA")}
                          {" "}
                          by
                          {" "}
                          {lastPasswordReset.admin_name}
                        </span>
                      )
                      : null
                  }
                </Col>
                <Col sm={4}>
                  <ButtonGroup>
                    <Button onClick={this.sendWelcomeEmail} color="info" outline>
                      Welcome Email
                    </Button>
                    <Button onClick={this.sendResetEmail} color="info" outline>
                      Reset Password Email
                    </Button>
                  </ButtonGroup>
                </Col>
              </Row>
            </td>
          </tr>
          <tr>
            <th className="align-middle">Receives Mailings</th>
            <td>
              <Switch
                checked={account.receives_mailings}
                name="receives_mailings"
                onChange={this.updateAccount}
              />
            </td>
          </tr>
          <tr>
            <th className="align-middle">Allow SMS</th>
            <td>
              <Switch
                checked={account.allow_sms}
                name="allow_sms"
                onChange={this.updateAccount}
              />
            </td>
          </tr>
          <tr>
            <th className="align-middle">Recent Logins</th>
            <td>
              {this.renderLogins(this.sortById(account.logins))}
            </td>
          </tr>
          <tr>
            <th className="align-middle">Locks</th>
            <td>
              <ol className="list-unstyled m-0">
                {sortedLocks.slice(0, 5).map((l) => (
                  <li className="d-flex flex-column" key={l.id}>
                    <span>
                      Locked on:
                      {" "}
                      {moment.utc(l.inserted_at).local().format("MM/DD/YYYY hh:mmA")}
                      .
                    </span>
                    <span>
                      Reason:
                      <b>{l.reason}</b>
                      {" "}
                      {l.admin && `Locked by: ${l.admin}`}
                    </span>
                    <span>
                      {!l.enabled ? (
                        <span>
                          Unlocked on:
                          {moment.utc(l.updated_at).local().format("MM/DD/YYYY hh:mmA")}
                        </span>
                      ) : ""}
                    </span>
                    <hr />
                  </li>
                ))}
              </ol>
            </td>
          </tr>
        </tbody>
      </Table>
    );
  }
}

export default AccountDetails;
