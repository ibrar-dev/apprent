import React, {Component} from 'react';
import {connect} from 'react-redux';
import {Button, Table, Popover, PopoverBody} from 'reactstrap';
import {CSVLink} from "react-csv";
import moment from 'moment';
import JsPDF from 'jspdf';
import DelinquencyReport from './delinquencyRow';
import FancyCheck from '../../../../components/fancyCheck';
import DatePicker from '../../../../components/datePicker';
import {toCurr, titleize} from '../../../../utils';
import actions from '../../actions';

const getLevel = (daysLate) => {
  if (daysLate < 31) return 0;
  if (daysLate < 61) return 1;
  if (daysLate < 91) return 2;
  return 3;
};

const breakdown = (charges, owed) => {
  let balance = owed;
  return charges.reduce((sums, charge) => {
    if (balance <= 0) return sums;
    const amount = charge.amount > balance ? balance : charge.amount;
    balance -= charge.amount;
    const level = getLevel(charge.days_late);
    sums[level] = sums[level] + amount;
    return sums;
  }, [0, 0, 0, 0]);
};

const header = ["Unit", "ID", "Resident", "Status", "Total Owed", '0-30 days', '31-60 days', '61-90 days', 'Over 90 days'];

class Delinquency extends Component {
  state = {
    delinquency: true,
    current: true,
    eviction: true,
    notice: true,
    past: false,
    description: '',
    filter: '',
    currentTenant: '',
    property_id: '',
    memos: {},
    asOfDate: moment().format('YYYY-MM-DD'),
    accountsReceivable: false
  };

  componentDidMount() {
    const property_id = this.props.property.id;
    this.setState({property_id: property_id})
  }

  residentsToShow(reportData) {
    const {memos} = this.state;

    const newReports = reportData.map(d => {
      if (memos[d.tenant_id]) {
        d['memo'] = memos[d.tenant_id];
      }
      return d;
    });
    return newReports.filter(this.shouldDisplay.bind(this)).filter(this.statusFilter.bind(this));
  }

  statusFilter(t) {
    const {current, eviction, notice, past} = this.state;
    if (current && t.status === "current") return true;
    if (eviction && t.status === "eviction") return true;
    if (past && t.status === "moved_out") return true;
    return (notice && t.status === "notice");
  }

  shouldDisplay(t) {
    const {delinquency} = this.state;
    if (delinquency) {
      return t.owed > 0;
    } else {
      return true;
    }
  }

  chargesFilter(t) {
    const {accountsReceivable} = this.state;
    if (accountsReceivable) {
      return t.charges.filter(c => c.account === "Rent")
    } else {
      return t.charges
    }
  }

  // calculateTotal(reportData) {
  //   return reportData.reduce((acc, t) => t.owed + acc, 0.00).toFixed(2);
  // }

  calculateTotal(totals){
    return totals.reduce((acc, t) => acc + t, 0);
  }

  change(type, value) {
    this.setState({...this.state, [type]: !value})
  }

  createExportData(data){
    const totals = [0, 0, 0, 0];
    const completeData = this.sortReport(data).map(t => {
      const itemized = breakdown(this.chargesFilter(t), t.owed);
      const getTotal = itemized.reduce((c, acc) => acc + c, 0);
      itemized.forEach((col, index) => totals[index] = totals[index] + col);
      return [t.unit, t.tenant_id, t.tenant, titleize(t.status),toCurr(getTotal), toCurr(itemized[0]), toCurr(itemized[1]), toCurr(itemized[2]), toCurr(itemized[3])];
    });
    completeData.push(["", "", "", "", toCurr(this.calculateTotal(data)), toCurr(totals[0]), toCurr(totals[1]), toCurr(totals[2]), toCurr(totals[3])]);
    return completeData;
  }

  csvData(data){
    const completeData = this.createExportData(data);
    completeData.unshift(header);
    return completeData;
  }

  pdfExport(data) {
    const {property} = this.props;
    const pdfArray = this.createExportData(data);
    const date = moment(this.state.asOfDate).format('MMMM DD, YYYY HH:mmA');
    const doc = new JsPDF({orientation: 'landscape'});
    doc.autoTable({
      head: [header],
      body: pdfArray,
      theme: 'grid',
      headStyles: {fillColor: [5, 55, 135]},
      columnStyles: {
        0: {cellWidth: 18, fontSize: 8},
        1: {cellWidth: 20, fontSize: 8},
        2: {cellWidth: 40, fontSize: 8},
        3: {cellWidth: 21, fontSize: 8},
        4: {cellWidth: 21, fontSize: 8},
        5: {cellWidth: 21, fontSize: 8},
        6: {cellWidth: 21, fontSize: 8},
        7: {cellWidth: 21, fontSize: 8},
        8: {cellWidth: 45, fontSize: 8}
      }
    });
    doc.output('bloburl');
    doc.save(`DQReport-${property.name}-${date}.pdf`)
  }

  createExcel(){
    const {current, eviction, notice, past, property_id, asOfDate, accountsReceivable} = this.state;
    const filters = [];
    const date = moment(asOfDate).format('YYYY-MM-DD');
    if(current) filters.push("current");
    if(eviction) filters.push("eviction");
    if(notice) filters.push("notice");
    if(past) filters.push("moved_out");
    actions.downloadDQExcel(property_id, filters, date, accountsReceivable)
  }

  updateFilter(e) {
    this.setState({filter: e.target.value.toLowerCase()});
  }

  updateAsOfDate(date) {
    this.setState({
      asOfDate: moment(date).format('YYYY-MM-DD')
    }, () => actions.fetchDatedReport('delinquency', this.props.property, moment(date).format('YYYY-MM-DD')))
  }

  closeMenu() {
    this.setState({popoverOpen: false});
  }

  openMenu() {
    this.state.popoverOpen || document.addEventListener('click', this.closeMenu.bind(this), {once: true});
    this.setState({popoverOpen: !this.state.popoverOpen});
  }

  sortReport(reportData) {
    return reportData.sort((a, b) => a.unit > b.unit ? 1 : -1)
    // sort((a, b) => a.unit > b.unit ? 1 : -1);
  }

  render() {
    const {reportData, property} = this.props;
    const {delinquency, current, eviction, notice, asOfDate, popoverOpen, past, accountsReceivable} = this.state;
    const date = moment().format('MMMM DD, YYYY HH:mmA');
    const data = reportData.length ? this.residentsToShow(reportData) : [];
    const totals = [0, 0, 0, 0];
    return <React.Fragment>
      <div className="d-flex justify-content-between align-items-center">
        <div className="d-flex align-items-center">
          <DatePicker value={asOfDate} onChange={this.updateAsOfDate.bind(this)}/>
        </div>
        <div className="d-flex align-items-center">
          <FancyCheck checked={delinquency} onChange={this.change.bind(this, 'delinquency', delinquency)}/>
          <div className="ml-2">Delinquent</div>
        </div>
        <div className="d-flex align-items-center">
          <FancyCheck type="checkbox" checked={current} onChange={this.change.bind(this, 'current', current)}/>
          <div className="ml-2">Current Residents</div>
        </div>
        <div className="d-flex align-items-center">
          <FancyCheck type="checkbox" checked={notice} onChange={this.change.bind(this, 'notice', notice)}/>
          <div className="ml-2">Notice Residents</div>
        </div>
        <div className="d-flex align-items-center">
          <FancyCheck type="checkbox" checked={eviction} onChange={this.change.bind(this, 'eviction', eviction)}/>
          <div className="ml-2">Eviction Residents</div>
        </div>
        <div className="d-flex align-items-center">
          <FancyCheck type="checkbox" checked={past} onChange={this.change.bind(this, 'past', past)}/>
          <div className="ml-2">Past Residents</div>
        </div>
        <div className="d-flex align-items-center">
          <FancyCheck type="checkbox" checked={accountsReceivable} onChange={this.change.bind(this, 'accountsReceivable', accountsReceivable)}/>
          <div className="ml-2">AR Aging</div>
        </div>
        <Button id="more-options-btn" outline color="info" className="d-flex" onClick={this.openMenu.bind(this)}>
          <i className="fas fa-ellipsis-v font-sze"/>
        </Button>
        <Popover placement="bottom" isOpen={popoverOpen} target="more-options-btn" className="popover-max"
                 toggle={this.closeMenu.bind(this)}>
          <PopoverBody className="d-flex flex-column">
            {/*<Button className="mb-2" onClick={this.addLateFees.bind(this)} outline>Add Late Fees</Button>*/}
            <Button className="mb-2" onClick={this.pdfExport.bind(this, data)} outline>
              Export PDF
            </Button>
            <CSVLink data={this.csvData(data)} filename={`Property-Report-${date}`} className="btn btn-outline-secondary">
              Export CSV
            </CSVLink>
            <Button className="mt-2" onClick={this.createExcel.bind(this)} outline>
              Export Excel
            </Button>
          </PopoverBody>
        </Popover>
      </div>
      <Table className="mt-2" striped>
        <thead>
        <tr>
          <th>Unit</th>
          <th>ID</th>
          <th>Resident</th>
          <th>Status</th>
          <th>Total Owed</th>
          <th>0 - 30 days</th>
          <th>31 - 60 days</th>
          <th>61 - 90 days</th>
          <th>Over 90</th>
        </tr>
        </thead>
        <tbody>
        {reportData.length > 0 && this.sortReport(data).map(t => {
          const itemized = breakdown(this.chargesFilter(t), t.owed);
          // const itemized = breakdown(t.charges, t.owed);
          itemized.forEach((col, index) => totals[index] = totals[index] + col);
          return <DelinquencyReport key={`${t.unit}-${t.tenant_id}`} data={t} itemized={itemized} propertyId={property.id} />;
        })}
        <tr>
          <th>Grand Total</th>
          <td/>
          <td/>
          <td/>
          <th>{toCurr(this.calculateTotal(totals))}</th>
          <th>{toCurr(totals[0])}</th>
          <th>{toCurr(totals[1])}</th>
          <th>{toCurr(totals[2])}</th>
          <th>{toCurr(totals[3])}</th>
        </tr>
        </tbody>
      </Table>
    </React.Fragment>
  }
}

export default connect(({property, reportData}) => {
  return {property, reportData}
})(Delinquency)
