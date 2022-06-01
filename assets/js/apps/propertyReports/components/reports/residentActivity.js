import React from 'react';
import {connect} from 'react-redux';
import actions from '../../actions';
import {activityHeaders, firstContact, paymentReport} from '../report_component/boxscore_headers';
import Pagination from "../../../../components/pagination";
import {Button, ButtonGroup, Card, CardBody, CardHeader, Col, Modal, Row, Table, Popover, PopoverBody} from 'reactstrap';
import {toCurr} from "../../../../utils";
import UnitStatus from '../report_component/unitStatus';
import DatePicker from '../../../../components/datePicker';
import {FirstContact} from '../report_component/boxscore_component';
import moment from 'moment';
import PaymentApplicant from '../report_component/payment_report';
import jsPDF from 'jspdf';
import {CSVLink} from "react-csv";

class Lease extends React.Component{
    render(){
        const {modal, leaseInfo, type} = this.props;
        return <Modal className="modal-lg" isOpen={modal} toggle={this.props.toggle}>
            <Card>
                <CardHeader>{type}</CardHeader>
                <CardBody>
                    <Table>
                        <thead>
                        <tr>
                            <th>Unit</th>
                            <th>Resident</th>
                            <th>Floor Plan</th>
                            <th>Rent Amount</th>
                            <th>Start Date</th>
                            <th>End Date</th>
                        </tr>
                        </thead>
                        <tbody>
                        {leaseInfo}
                        </tbody>
                    </Table>
                </CardBody>
            </Card>
        </Modal>
    }
}

class ResidentActivityRow extends React.Component{
    state = {};

    showNumbers(arr){
        return arr ? arr.length : 0;
    }

    leaseInfo(leases = []){
        return leases.map(({leases, floor_plan, rent_amount, tenants, unit_number}) => {
            return <tr key={leases.id}>
                <td>{unit_number}</td>
                <td>{tenants.map(t => <Row key={t.id}>
                    <a href={`/tenants/${t.id}`} target="_blank">{t.first_name} {t.last_name}</a>
                    </Row>)}
                </td>
                <td>{floor_plan.name}</td>
                <td>{rent_amount.map(r => <Row key={r.id}>
                    <strong>{r.name}: {toCurr(r.amount)}</strong>
                    </Row>)}
                </td>
                <td>{leases.start_date}</td>
                <td>{leases.end_date}</td>
            </tr>
        })
    }

    setFields(data, type){
        if(data){
            this.setState({modalData: data, header: type, modal: true});
        }
    }

    toggleModal(){
        this.setState({modal: false});
    }

    render(){
        const {res_act: {type, move_in, move_out, onsite_transfer, renewal, mtm, evictions, units}} = this.props;
        const {modal, modalData, header} = this.state;
        return <tr>
            <td>{type}</td>
            <td>{units}</td>
            <td onClick={this.setFields.bind(this, move_in, `Move In - ${type}`)}
                className="lease-show">{this.showNumbers(move_in)}</td>
            <td onClick={this.setFields.bind(this, move_out, `Move Out - ${type}`)}
                className="lease-show">{this.showNumbers(move_out)}</td>
            <td onClick={this.setFields.bind(this, onsite_transfer, `Onsite Transfer - ${type}`)}
                className="lease-show">{this.showNumbers(onsite_transfer)}</td>
            <td onClick={this.setFields.bind(this, renewal, `Renewal - ${type}`)}
                className="lease-show">{this.showNumbers(renewal)}</td>
            <td onClick={this.setFields.bind(this, mtm, `Month to Month - ${type}`)}
                className="lease-show">{this.showNumbers(mtm)}</td>
            <td onClick={this.setFields.bind(this, evictions, `Evictions - ${type}`)}
                className="lease-show">{this.showNumbers(evictions)}</td>
            <Lease leaseInfo={this.leaseInfo(modalData)} modal={modal} type={header} toggle={this.toggleModal.bind(this)}/>
        </tr>
    }
}

class BoxScore extends React.Component{

    state = {mode: 'box-avail', start_date: moment().subtract(1, 'months').format("YYYY-MM-DD"), end_date: moment().format("YYYY-MM-DD")};

    componentDidMount(){
        const {start_date, end_date} = this.state;
        actions.fetchNewBoxScore({start_date: start_date, end_date: end_date})
        actions.fetchUnitStatus(end_date);
    }

    fetchNewBoxScore(mode){
        const {start_date, end_date} = this.state;
        if(mode != "box-avail") actions.fetchNewBoxScore({start_date: start_date, end_date: end_date})
        else actions.fetchUnitStatus(end_date);
    }

    setMode(mode){
        const {start_date, end_date} = this.state;
        const newState = {...this.state, mode: mode};
        if(start_date > end_date) newState.start_date = moment(end_date).subtract(1, 'months').format("YYYY-MM-DD");
        this.setState(newState, this.fetchNewBoxScore.bind(this, mode));
    }

    findMode(){
        const {mode} = this.state;
        switch(mode){
            // case "box-avail":
            //     return {title: 'Availability', field: 'avail', component: UnitStatus, headers: []};
            case "box-res":
                return {title: 'Resident Activity', field: 'res_act', component: ResidentActivityRow, headers: activityHeaders};
            case "box-cont":
                return {title: 'First Contact', field: 'contact', component: FirstContact, headers: firstContact};
            case "applicant-report":
                return {title: 'Applicant Report', field: 'payment_report', component: PaymentApplicant, headers: paymentReport};
            default:
                return {};
        }
    }

    createPagination(){
        const {title, field, component, headers} = this.findMode();
        const {mode, start_date, end_date} = this.state;
        if(mode === "box-avail") return <UnitStatus ref="unitStatus" start_date={start_date} end_date={end_date} unitStatus={this.props.unitStatus} />
        return <Pagination collection={this.filtered()}
            title={title}
            field={field}
            component={component}
            headers={headers}
        />
    }

    filtered(){
        const {mode} = this.state
        const {newBoxScore:{box_score, tours, payments, non_format}} = this.props;
        switch(mode){
            case "box-res":
                return Object.keys(box_score).map(b => {
                    return {...box_score[b], type: b};
                });
            case "box-cont":
                return Object.keys(tours).map(b => {
                    return {...tours[b], type: b};
                });
            case "applicant-report":
                let total = 0;
                payments.forEach(p => total += parseInt(p.amount));
                const totalReport = [{date: "Total", amount: total}];
                return totalReport.concat(payments);
            default:
                return [];
        }
    }

    createPdf(doc, body, headers, title, columnStyles){
      doc.text(title, 40, (doc.autoTable.previous.finalY || 40) + 40);
      doc.autoTable({
        startY: (doc.autoTable.previous.finalY || 40) + 50,
        head: [headers],
        body: body,
        theme: 'grid',
        headStyles: {fillColor: [5, 55, 135]},
        columnStyles: columnStyles,
        didDrawPageContent: function (data) {
          doc.text(headerString, 40, 30);
        }
      })
    }

    exportArray(){
      const {mode} = this.state;
      const {newBoxScore:{non_format, payments, non_format_box_score}} = this.props;

      switch(mode){
          case "box-res":
            return Object.keys(non_format_box_score).reduce((acc,k) => {
              if(non_format_box_score[k][0]){
                const headers = ['Unit', 'Floor Plan', 'Resident', 'Rent', 'Start Date', 'End Date'];
                const body = non_format_box_score[k].map(nfbs => {
                  const {unit_number, floor_plan, tenants, rent_amount, start_date, end_date} = nfbs;
                  return [unit_number, floor_plan.name, tenants.map(t => `${t.first_name} ${t.last_name}`), rent_amount.map(ra => `${ra.name} - ${ra.amount}`), start_date, end_date]
                });
                acc.push({headers: headers, body: body, title: k.split("_").map(b => b.charAt(0).toUpperCase() + b.slice(1)).join(" "), columnStyles: {}});
              }
              return acc;
            }, []);
          case "box-cont":
              const runningBody = [];
              const tourHeaders = ["Floor Plan", "Name", "Showing Date", "Start Time", "End Time", "Contact Type", "Phone"];
              const tourBody = non_format.tours.map(tenant => {
                  const {unit_type, name, date, start_time, end_time, contact_type, phone} = tenant;
                  return [unit_type || "Not Specified", name, date, start_time, end_time, contact_type, phone];
              })
              runningBody.push({headers: tourHeaders, body: tourBody, title: "Tours", columnStyles: {}})
              const appHeaders = ["Floor Plan", "Name", "Phone", "Contact Type", "Contact Date", "Date Applied", "Status"]
              const appBody = non_format.applicants.map(applicant => {
                const {unit_type, phone, contact_type, name, contact_date, property_name, application_submitted} = applicant
                return [unit_type || "Not Specified", name, phone, contact_type, contact_date, application_submitted, status]
              });
              runningBody.push({headers: appHeaders, body: appBody, title: "Applicants", columnStyles: {}})
              return runningBody;
          case "applicant-report":
              const headers = ["Date", "Amount", "Description", "Transaction ID", "Account ID"]
              const body = payments.map(p => {
                const {date, description, amount, applicant, transaction_id, response} = p;
                return [date, amount, description, transaction_id, response.account_id];
              })
              return [{headers: headers, body: body, title: "Payments", columnStyles: {}}]
          default:
              return [];
      }
    }

    downloadPdf(){
        const {mode, start_date, end_date} = this.state
        if(mode === "box-avail") return this.refs.unitStatus.pdf();
        const doc = new jsPDF('l', 'pt', 'a4');
        const exportArray = this.exportArray();
        const {title} = this.findMode();
        doc.text(`${title} ${start_date} - ${end_date}`, 40, 40);
        exportArray.forEach(eA => {
          const {headers, body, title, columnStyles} = eA;
          this.createPdf(doc, body, headers, title, columnStyles)
        });
        doc.save(`${title} ${start_date} - ${end_date}.pdf`)
    }

    createCSV(){
      const {mode, start_date, end_date} = this.state;
      if(this.refs.unitStatus && mode === "box-avail") return this.refs.unitStatus.csv();
      const body = this.exportArray().reduce((acc,eA) => {
        const {headers, body, title, columnStyles} = eA;
        const newTitle = new Array(headers.length).fill("");
        newTitle[0] = title;
        acc = acc.concat([newTitle].concat([headers]).concat(body));
        return acc;
      }, []);
      const {title} = this.findMode();
      return {csvBody: body, csvTitle: `${title} ${start_date} - ${end_date}`};
    }

    change({target: {name, value}}) {
        this.setState({...this.state, [name]: value.format("YYYY-MM-DD")}, this.fetchNewBoxScore.bind(this, this.state.mode));
    }

    closeMenu() {
      this.setState({popoverOpen: false});
    }

    openMenu() {
      this.state.popoverOpen || document.addEventListener('click', this.closeMenu.bind(this), {once: true});
      this.setState({popoverOpen: !this.state.popoverOpen});
    }

    render() {
        const {mode, start_date, end_date, popoverOpen} = this.state;
        const {csvBody, csvTitle} = this.createCSV();
        return <React.Fragment>
            <div className="d-flex justify-content-center mb-4">
                <ButtonGroup style={{width: 506}}>
                    <Button outline color="info" onClick={this.setMode.bind(this, 'box-avail')}
                            active={mode === 'box-avail'}>Availability</Button>
                    <Button outline color="info" onClick={this.setMode.bind(this, 'box-res')} active={mode === 'box-res'}>Resident Activity</Button>
                    <Button outline color="info" onClick={this.setMode.bind(this, 'box-cont')} active={mode === 'box-cont'}>First Contact</Button>
                    <Button outline color="info" onClick={this.setMode.bind(this, 'applicant-report')} active={mode === 'applicant-report'}>Applicant Report</Button>
                </ButtonGroup>
                <div className="ml-4">
                <Button id="res-download-btns" outline color="info" className="d-flex" onClick={this.openMenu.bind(this)}>
                  <i className="fas fa-ellipsis-v font-sze"/>
                </Button>
                <Popover placement="bottom" isOpen={popoverOpen} target="res-download-btns" className="popover-max"
                         toggle={this.closeMenu.bind(this)}>
                  <PopoverBody className="d-flex flex-column">
                    {/*<Button className="mb-2" onClick={this.addLateFees.bind(this)} outline>Add Late Fees</Button>*/}
                    <Button className="mb-2" onClick={this.downloadPdf.bind(this)} outline>
                      Export PDF
                    </Button>
                    <CSVLink data={csvBody} filename={csvTitle} className="btn btn-outline-secondary">
                      Export CSV
                    </CSVLink>
                  </PopoverBody>
                </Popover>
                </div>
            </div>
            <div className="d-flex justify-content-center mb-4">
                {mode !== 'box-avail' && <div className="mr-2 labeled-box" style={{width: 250}}>
                    <DatePicker onChange={this.change.bind(this)} value={start_date} name="start_date"/>
                    <div className="labeled-box-label">Start Date</div>
                </div>}
                <div className="labeled-box" style={{width: 250}}>
                    <DatePicker onChange={this.change.bind(this)} value={end_date} name="end_date"/>
                    <div className="labeled-box-label">End Date</div>
                </div>
            </div>
            {this.createPagination()}
        </React.Fragment>
    }
}

export default connect(({newBoxScore, unitStatus, property}) => {
    return {newBoxScore, unitStatus, property};
})(BoxScore);
