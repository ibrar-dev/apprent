import React from 'react';
import moment from 'moment';
import Select from '../../../../components/select';
import classnames from 'classnames';
import Prospect from './prospect';

class Block extends React.Component {
  state = {};

  addShowing({target: {value}}) {
    const {date, start} = this.props;
    const formattedDate = moment(date).format('YYYY-MM-DD');
    this.setState({...this.state, date: formattedDate, start: start, duration: value})
    // actions.createShowing({
    //   start_time: start,
    //   end_time: start + value,
    //   date: formattedDate
    // }).catch(e => {
    //   setError(e.response.data.error);
    // })
  }

  reset() {
    this.setState({date: null});
  }

  render() {
    const {showing, start, interval, available, closure} = this.props;
    const {date, start: startTime, duration} = this.state;
    const styling = {
      'border-bottom-0': (showing && showing.end_time > start + interval) || (closure && closure.end_time > start + interval),
      'border-top-0': (showing && showing.start_time < start) || (closure && closure.start_time < start),
      'bg-info text-white': showing || closure,
      'text-center clickable align-middle min-react-select': true
    };
    return <td className={classnames(styling)}>
      {showing && showing.start_time === start && <div className="d-flex justify-content-between">
        <div>Unavailable</div>
      </div>}
      {closure && closure.start_time <= start && <div className="d-flex justify-content-between">
        <div>Office closed for {closure.reason}</div>
      </div>}
      {(!showing && !closure) && available && <Select value=""
                                        searchable={false}
                                        placeholder="Schedule showing"
                                        arrowRenderer={() => {
                                        }}
                                        options={[
                                          {value: 60, label: '1 hour'}
                                        ]}
                                        onChange={this.addShowing.bind(this)}/>}
      {date && <Prospect date={date}
                         toggle={this.reset.bind(this)}
                         start={startTime}
                         duration={duration}/>}
    </td>
  }
}

export default Block;