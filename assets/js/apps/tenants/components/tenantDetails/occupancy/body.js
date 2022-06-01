import React from 'react';
import {connect} from 'react-redux';
import {Table, CardBody, Col, Row, Input, Button} from "reactstrap";
import Select from "../../../../../components/select";
import moment from "moment";
import confirmationModal from "../../../../../components/confirmationModal";
import DatePicker from "../../../../../components/datePicker";
import canEdit from "../../../../../components/canEdit";
import actions from "../../../actions";

const picker = (name, value, handleChange, options = {clearable: true, customInputIcon: 'today'}) =>
  <DatePicker value={value} name={name} onChange={handleChange}{...options}/>;

const afterToday = (date) => date.isAfter(moment().endOf('day'))

class Body extends React.Component {
  state = {tenancy: {...this.props.tenant}, editMode: false};

  changeDate({target: {name, value}}) {
    const {tenancy} = this.state;
    const {tenant, lease} = this.props;
    if (name === 'notice_date' && value && moment.duration(moment(lease.end_date).diff(moment(value))).asDays() < tenant.property.notice_period) {
      {
        confirmationModal("The date provided by the tenant violates the lease by not giving enough notice.").then(() => {
          this.setState({tenancy: {...tenancy, [name]: value.format('YYYY-MM-DD')}});
        });
      }
    } else if (!tenancy.expected_move_out && name === "actual_move_out") {
      let date = value ? moment(value._d).format('YYYY-MM-DD') : value;
      this.setState({tenancy: {...this.state.tenancy, actual_move_out: date, expected_move_out: date}});
    } else {
      this.setState({tenancy: {...this.state.tenancy, [name]: value ? moment(value._d).format('YYYY-MM-DD') : value}});
    }
  }

  toggleClose() {
    this.setState({editMode: false, lease: {...this.props.lease}});
  }

  moveOutReason() {
    return this.props.moveOutReasons.find((option) => {
      return option.id === this.props.tenant.move_out_reason_id
    });
  }

  actionButtons() {
    const {tenant} = this.props;
    const buttons = [];
    if (canEdit(['Super Admin'])) buttons.push(
      <Button color="info" outline onClick={this.toggleEdit.bind(this)}>Edit</Button>
    );
    return buttons.map((action, index) => <div key={index} className="mx-2">{action}</div>);
  }

  fields(name) {
    const changeDate = this.changeDate.bind(this);
    const {tenancy} = this.state;
    const datePicker = {
      expected_move_in: picker('expected_move_in', tenancy.expected_move_in, changeDate, {clearable: true}),
      actual_move_in: picker('actual_move_in', tenancy.actual_move_in, changeDate, {
        clearable: true,
        isOutsideRange: afterToday
      }),
      expected_move_out: picker('expected_move_out', tenancy.expected_move_out, changeDate, {clearable: true}),
      actual_move_out: picker('actual_move_out', tenancy.actual_move_out, changeDate, {
        clearable: true,
        isOutsideRange: afterToday
      }),
      notice_date: picker('notice_date', tenancy.notice_date, changeDate, {
        clearable: true,
        isOutsideRange: afterToday
      }),
      move_out_reason_id: <Select value={tenancy.move_out_reason_id} name="move_out_reason_id"
                                  onChange={this.change.bind(this)}
                                  options={this.props.moveOutReasons.map(m => {
                                    return {label: m.name, value: m.id};
                                  })}/>
    };
    return (datePicker[name])
  }

  toggleEdit() {
    this.setState({editMode: !this.state.editMode});
  }

  change({target: {name, value}}) {
    this.setState({tenancy: {...this.state.tenancy, [name]: value}});
  }

  save() {
    actions.updateTenancy(this.state.tenancy).catch(r => {
      confirmationModal(r.response.data.error, {header: 'Error', noCancel: true});
    });
    this.setState({editMode: false, activeActionComponents: []});
  }

  render() {
    const {tenant} = this.props;
    const {editMode} = this.state;
    return <CardBody>
      <Row style={{backgroundColor: '#f7f9fc', margin: '20px 2px', boxShadow: '0 1px 4px rgba(0, 0, 0, 0.3)'}}>
        <Col xl={6} lg={12}>
          <Table borderless className="m-0">
            <tbody>
            <tr>
              <th className="nowrap align-middle border-0">
                Tenant(s)
              </th>
              <td className="nowrap align-middle border-0" style={{padding: '0.5rem 0.75rem'}}>
                <div className="d-flex">
                  <div>{tenant.first_name} {tenant.last_name}</div>
                  {tenant.other_tenants.map(t => {
                    if (tenant.id === t.id) return null;
                    return <React.Fragment key={t.id}>
                      <span>, </span>
                      <a className="text-info ml-2" href={`/tenants/${t.tenancy_id}`}>{t.first_name} {t.last_name}</a>
                    </React.Fragment>;
                  })}
                </div>
              </td>
            </tr>
            <tr>
              <th className="nowrap align-middle">
                Notice Given Date
              </th>
              <td className="nowrap align-middle">
                {editMode ? this.fields('notice_date') : tenant.notice_date || "  - -"}
              </td>
            </tr>

            <tr>
              <th className="nowrap align-middle">
                Actual Move In Date
              </th>
              <td className="nowrap align-middle">
                {editMode ? this.fields('actual_move_in') : tenant.actual_move_in || "  - -"}
              </td>
            </tr>
            <tr>
              <th className="nowrap align-middle">
                Actual Move Out Date
              </th>
              <td className="nowrap align-middle">
                {editMode ? this.fields('actual_move_out') : tenant.actual_move_out || "  - -"}
              </td>
            </tr>
            </tbody>
          </Table>
        </Col>
        <Col xl={6} lg={12}>
          <Table borderless className="m-0">
            <tbody>
            <tr>
              <th className="nowrap align-middle border-0">
                Unit
              </th>
              <td className="border-0 nowrap align-middle">
                <a href={`/units/${tenant.unit.id}`}>{tenant.property.name} {tenant.unit.number}</a>
              </td>
            </tr>
            <tr>
              <th className="nowrap align-middle">
                Expected Move In Date
              </th>
              <td>
                {editMode ? this.fields('expected_move_in') : tenant.expected_move_in || "  - -"}
              </td>
            </tr>
            <tr>
              <th className="nowrap align-middle">
                Expected Move Out Date
              </th>
              <td>
                {editMode ? this.fields('expected_move_out') : tenant.expected_move_out || "  - -"}
              </td>
            </tr>
            <tr>
              <th className="nowrap align-middle">
                Move Out Reason
              </th>
              <td>
                <div style={{margin: '-1px 0 -2px 0'}}>
                  {editMode ? this.fields('move_out_reason_id') : tenant.move_out_reason_id ? this.moveOutReason().name : "  - -"}
                </div>
              </td>
            </tr>
            </tbody>
          </Table>
          {editMode && <Col className="m-3 d-flex justify-content-end">
            <Button outline onClick={this.toggleClose.bind(this)}>Cancel</Button>
            <Button color="success" onClick={this.save.bind(this)} className="ml-2">
              <i className="fas fa-check"/> Save
            </Button>
          </Col>}
        </Col>
      </Row>
      <div className="d-flex">{this.actionButtons()}</div>
    </CardBody>;
  }
}

export default connect(({moveOutReasons}) => ({moveOutReasons}))(Body);