import React from "react";
import {
  Card,
  CardBody,
  Table,
  Input,
  Button,
  FormFeedback,
  FormGroup,
} from "reactstrap";
import Select from "../../../../../components/select";
import actions from "../../../actions";

const paymentStatus = [
  {label: "Approved", value: "approved"},
  {label: "Cash Only", value: "cash"},
];

const emailError = "This email address is invalid. Emails to it will bounce. Please correct the email address or delete it completely.";
class Profile extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      tenant: props.tenant,
      errors: this.setInitialErrors(props.tenant),
    };

    this.change = this.change.bind(this);
    this.toggleEditMode = this.toggleEditMode.bind(this);
    this.syncExternalId = this.syncExternalId.bind(this);
    this.setEmailAsValid = this.setEmailAsValid.bind(this);
  }

  setInitialErrors(tenant) {
    return tenant.invalid_email || !this.validateEmail(tenant.email) ? {email: emailError} : {};
  }

  toggleEditMode() {
    const {editMode, tenant} = this.state;
    if (editMode) {
      actions.updateTenant(tenant.tenant_id, tenant);
    }
    this.setState({editMode: !editMode});
  }

  validateEmail(email) {
    if (email === "") return true;
    const re = /.{2,}@.{1,}\..{2,}/;
    return re.test(email);
  }

  change({target: {name, value}}) {
    if (name === "email") {
      const errors = this.validateEmail(value) ? {} : {email: emailError};
      this.setState({errors});
    }
    const {tenant} = this.state;
    this.setState({tenant: {...tenant, [name]: value}});
  }

  syncExternalId() {
    const {tenant} = this.state;
    actions.syncTenantExternalId(tenant.id).then((r) => {
      this.setState({tenant: {...tenant, external_id: r.data.success}});
    });
  }

  setEmailAsValid() {
    const {id} = this.props.tenant;
    actions.setTenantEmailAsValid(id).then(() => {
      const errors = this.setInitialErrors(this.props.tenant);
      this.setState({errors});
    });
  }

  render() {
    const {tenant, editMode, errors} = this.state;
    const propertyId = tenant.unit.property_id;
    return (
      <Card className="border-top-0">
        <CardBody className="p-0">
          <Table className="m-0">
            <tbody>
              <tr>
                <th className="align-middle border-0">
                  First Name
                </th>
                <td className="border-0">
                  <Input
                    disabled={!editMode}
                    value={tenant.first_name}
                    name="first_name"
                    onChange={this.change}
                  />
                </td>
              </tr>
              <tr>
                <th className="align-middle">
                  Last Name
                </th>
                <td>
                  <Input
                    disabled={!editMode}
                    value={tenant.last_name}
                    name="last_name"
                    onChange={this.change}
                  />
                </td>
              </tr>
              <tr style={{height: errors.email ? 160 : 59}}>
                <th className="align-middle">
                  Email
                </th>
                <td>
                  <FormGroup className="position-relative">
                    <Input
                      disabled={!editMode}
                      value={tenant.email || ""}
                      name="email"
                      type="email"
                      onChange={this.change}
                      invalid={!!errors.email}
                    />
                    {
                      errors.email && (
                        <FormFeedback tooltip>
                          {errors.email}
                        </FormFeedback>
                      )
                    }
                  </FormGroup>
                  {
                    errors.email && (
                      <div className="text-right pt-5" style={{paddingRight: "0.75rem", paddingBottom: "0.75rem"}}>
                        <Button onClick={this.setEmailAsValid} color="info">
                          Update Email as Valid
                        </Button>
                      </div>
                    )
                  }
                </td>
              </tr>
              <tr>
                <th className="align-middle">
                  Phone
                </th>
                <td>
                  <Input
                    disabled={!editMode}
                    value={tenant.phone || ""}
                    name="phone"
                    onChange={this.change}
                  />
                </td>
              </tr>
              <tr>
                <th className="align-middle">
                  Alarm Code
                </th>
                <td>
                  <Input
                    disabled={!editMode}
                    value={tenant.alarm_code || ""}
                    name="alarm_code"
                    onChange={this.change}
                  />
                </td>
              </tr>
              <tr>
                <th className="align-middle">
                  Payment Status
                </th>
                <td>
                  <Select
                    disabled={!editMode}
                    value={tenant.payment_status}
                    options={paymentStatus}
                    name="payment_status"
                    onChange={this.change}
                  />
                </td>
              </tr>
              <tr>
                <th className="align-middle">
                  MoneyGram ID Number
                </th>
                <td>
                  {`0000${propertyId}`.substr(-4, 4)}
                  {tenant.tenant_id}
                </td>
              </tr>
              <tr>
                <th>
                  External ID
                </th>
                <td>
                  <div className="d-flex">
                    <Input
                      disabled={!editMode}
                      value={tenant.external_id || ""}
                      name="external_id"
                      onChange={this.change}
                    />
                    <div className="ml-2">
                      <Button color="success" onClick={this.syncExternalId}>
                        Sync
                      </Button>
                    </div>
                  </div>
                </td>
              </tr>
            </tbody>
          </Table>
          <div className="text-right pb-2" style={{paddingRight: "0.75rem", paddingBottom: "0.75rem"}}>
            <Button
              onClick={this.toggleEditMode}
              color={editMode ? "success" : "info"}
              className="mt-0 ml-2 w-25"
              disabled={editMode && Object.keys(errors).length > 0}
            >
              {editMode ? "Save" : "Edit"}
            </Button>
          </div>
        </CardBody>
      </Card>
    );
  }
}

export default Profile;
