import React from 'react';
import {connect} from 'react-redux';
import moment from 'moment';
import {Modal, ModalBody, Button} from 'reactstrap';
import actions from '../../actions';
import {safeRegExp, toCurr} from '../../../../utils';
import Pagination from '../../../../components/pagination';

const headers = [
  {label: 'Date', min: true},
  {label: 'Post Month', min: true},
  {label: 'Desc'},
  {label: 'Debit'},
  {label: 'Credit'},
  {label: 'Balance'}
];

class Detail extends React.Component {
  render() {
    const {detail} = this.props;
    if (detail.type === 'heading') {
      return <tr>
        <td/>
        <td/>
        <td><strong>{detail.desc}</strong></td>
        <td><strong>{toCurr(detail.totalDebit, '$')}</strong></td>
        <td><strong>{toCurr(detail.totalCredit, '$')}</strong></td>
        <td><strong>{toCurr(detail.balance, '$')}</strong></td>
      </tr>;
    } else {
      return <tr>
        <td>{moment(detail.date).format('MM/DD/YYYY')}</td>
        <td>{moment(detail.post_month).format('MM/YYYY')}</td>
        <td><a href={`/${detail.source}/${detail.ref}`} target="_blank">{detail.desc}</a></td>
        <td>{detail.type === 'debit' && toCurr(detail.amount, '$')}</td>
        <td>{detail.type === 'credit' && toCurr(detail.amount, '$')}</td>
        <td>{toCurr(detail.running_total, '$')}</td>
      </tr>;
    }
  }
}

class AccountDetail extends React.Component {
  constructor(props) {
    super(props);
    const {start, end} = props;
    this.state = {
      result: [],
      filter: '',
      start: start,
      end: end
    };
  }

  changeFilter(e) {
    this.setState({filter: e.target.value})
  }

  change({target: {name, value}}) {
    this.setState({[name]: value});
  }

  _filters() {
    const {filter} = this.state;
    return <input className="form-control" value={filter} onChange={this.changeFilter.bind(this)}/>
  }

  _filtered(result) {
    const {filter} = this.state;
    const test = safeRegExp(filter);
    return result.filter(d => (test.test(d.desc)));
  }

  componentWillMount() {
    const {reportType, start: propStart, end: propEnd, accountId} = this.props;
    const start = propStart || reportType.start_date;
    const end = propEnd || reportType.end_date;
    actions.fetchAccountDetail(accountId, reportType.property_ids, start, end, reportType.book).then(r => {
      const result = r.data.filter(d => !moment(d.post_month).isBefore(start));
      if (result.length === 0) return this.setState({noResults: true});
      const initialBalance = result[0].running_total - (result[0].amount * (result[0].type === 'credit' ? 1 : -1));
      const totals = {totalDebit: 0, totalCredit: 0};
      result.forEach(item => {
        if (item.type === 'debit') {
          totals.totalDebit = totals.totalDebit + item.amount
        } else {
          totals.totalCredit = totals.totalCredit + item.amount;
        }
      });
      const finalBalance = result[result.length - 1].running_total;
      if (!end) {
        const initial = {desc: 'Beginning Balance', balance: initialBalance, date: '0000-00-00', type: 'heading'};
        result.unshift(initial);
        result.push({
          desc: 'Net Change',
          date: '5000-01-01',
          type: 'heading',
          balance: Math.abs(finalBalance - initialBalance)
        });
      }
      result.push({...totals, desc: 'Totals', date: '3000-01-01', type: 'heading'});
      result.push({desc: 'Ending Balance', date: '4000-01-01', type: 'heading', balance: finalBalance});
      this.setState({noResults: false, result});
    })
  }

  downloadDetails(){
    const {reportType, start: propStart, end: propEnd, accountId} = this.props;
    const start = propStart || reportType.start;
    const end = propEnd || reportType.end;
    actions.accountDetailExcel(accountId, reportType.property_ids, start, end, reportType.book);
  }

  render() {
    const {accountName, toggle} = this.props;
    const {result, end, start, noResults} = this.state;
    return <Modal toggle={toggle} size="xl" isOpen={true}>
      <ModalBody>
        {noResults && <h3 className="m-0 text-center">No results for this date range.</h3>}
        {!noResults && <Pagination collection={this._filtered(result)}
                                   headers={headers}
                                   tableClasses="data-table"
                                   title={<div className="nowrap">
                                     <a className="mr-1" onClick={toggle}>
                                       <i className="fas fa-times text-danger"/>
                                     </a>
                                     Account Detail: {accountName} {start} {end && `- ${end}`}
                                     <Button className="ml-1 mr-1" outline onClick={this.downloadDetails.bind(this)}><i className="fas fa-file-excel" /></Button>
                                   </div>}
                                   component={Detail}
                                   toggleIndex={true}
                                   filters={this._filters()}
                                   field="detail"/>}
      </ModalBody>
    </Modal>;
  }
}

export default connect(({reportType}) => {
  return {reportType};
})(AccountDetail);