import React from 'react';
import {Button, Table, Alert} from 'reactstrap';
import moment from 'moment';
import {BarLoader} from 'react-spinners';
import Block from './block';
import {capitalize} from '../../../../utils';

const interval = 30;

const convertHours = (int) => {
  let base = Math.floor(int / 60);
  if (base > 12) base = base - 12;
  return base > 0 ? base + '' : '12';
};

const convertMins = int => `0${int % 60}`.replace(/\d(\d\d)/, '$1');

const convertTime = (time) => `${convertHours(time)}:${convertMins(time)}${time >= (12 * 60) ? 'P' : 'A'}M`;

class Day extends React.Component {
  state = {};

  back() {
    this.props.back(null)
  }
  
  setPending(value) {
    this.setState({...this.state, pending: value});
  }

  setError(e) {
    this.setState({...this.state, error: e});
  }

  render() {
    const {date, showings, openings, prospect} = this.props;
    const {error, pending} = this.state;
    return <div>
      <div className="d-flex justify-content-between align-item-center mb-2">
        <h3 className="d-flex align-items-center m-0">
          {moment(date).format("MMMM D, YYYY")}
        </h3>
        {error && <Alert className="m-0" color="danger" toggle={this.setError.bind(this, null)}>
          {capitalize(error.replace('_', ' '))}
        </Alert>}
        <Button onClick={this.back.bind(this)} color="danger">
          <i className="fas fa-arrow-circle-left"/> Back
        </Button>
      </div>
      {pending && <BarLoader height={15} width={"100%"} loading={true} color={'#312d45'} />}
      <Table bordered>
        <tbody>
        {openings.map(o => {
          const span = (o.end_time - o.start_time);
          const blocks = Math.floor(span / interval);
          return [...new Array(blocks)].map((b, index) => {
            const start = o.start_time + (interval * index);
            const slotShowings = showings.filter(s => s.start_time <= start && s.end_time >= start + interval);
            return <tr key={index}>
              <td className="min-width align-middle">{convertTime(start)}</td>
              {[...new Array(o.showing_slots)].map((b, i) => {
                return <Block key={i}
                              showing={slotShowings[i]}
                              available={i === 0 || slotShowings[i-1]}
                              date={date}
                              prospect={prospect}
                              interval={interval}
                              setError={this.setError.bind(this)}
                              setPending={this.setPending.bind(this)}
                              start={start}/>;
              })}
            </tr>
          });
        })}
        </tbody>
      </Table>
    </div>;
  }
}

export default Day;