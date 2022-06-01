import React, { Component } from 'react';
import Select from '../../../../components/select'
import actions from '../../actions'
import Pagination from '../../../../components/pagination'
import {Row, Col, Button, Input, Label} from 'reactstrap'
import Action from '../report_component/admin_action'
import DateRangePicker from '../../../../components/dateRangePicker';

class AdminActions extends Component {

  constructor(props){
    super(props);
    this.fetchAdmins()
    this.state = {admins: [], data: [], admin: '', filters: {payment: true, charge: true}}
  }

  changeDates({startDate, endDate}) {
    this.setState({startDate, endDate});
  }

  changeFilter(name){
    this.setState({filters: {...this.state.filters, [name]: !this.state.filters[name]}})
  }

 fetchAdmins(){
   actions.fetchAdmins()
   .then(({data}) => this.setState({admins: data.map(ad => ({label: ad.name, value: ad.id}))}))
 }

 filtered(){
   const {data, filters} = this.state;
   return data.filter(a => filters[a.type])
 }

 setAdmin({target: {name, value}}){
   this.setState({adminId: value})
 }

 fetchActions(){
   const {startDate, endDate, adminId} = this.state;
   if (startDate && endDate && adminId){
     actions.fetchAdminAction(adminId, startDate.format(), endDate.format())
     .then(r => {
       this.setState({data: r.data})
     })
   }
 }


  render() {
    const {admin, adminId, startDate, endDate, filters: {payment, charge}} = this.state;
    const data = this.filtered()
    return <>
    <Row className='m-4 p-2 justify-content-center d-flex'>
      <Col md={2} style={{width: '200px'}}>
        <Select placeholder='Select an admin.' onChange={this.setAdmin.bind(this)} value={adminId} options={this.state.admins}/>
      </Col>
      <Col md={4}>
       <DateRangePicker startDate={startDate} endDate={endDate} onDatesChange={this.changeDates.bind(this)}/>
      </Col>
      <Col md={1}>
        <Button disabled={!(adminId && startDate && endDate)} onClick={this.fetchActions.bind(this)} color='success'>Go</Button>
      </Col>
  </Row>
    <Row className='mt-4'>
        <Col>
      <Pagination
        collection={data}
        component={Action}
        toggleIndex={true}
        filters={<Col className='d-flex'>
          <Row>
           <Col><Label>Payments</Label></Col><Col><Input type='checkbox' onChange={this.changeFilter.bind(this, 'payment')} checked={payment}/></Col>
           <Col><Label>Charges</Label></Col><Col><Input onChange={this.changeFilter.bind(this, 'charge')} type='checkbox' checked={charge}/></Col>
          </Row>
        </Col>}
        headers={[
          {label: 'Date'},
          {label: 'Type'},
          {label: 'Description'},
          {label: 'Amount'},
          {label: 'Tenant'}
        ]}
        field="action"
        />
      </Col>
    </Row>
    </>
  }

}

export default AdminActions;
