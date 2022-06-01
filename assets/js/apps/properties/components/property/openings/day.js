import React from 'react';
import {connect} from 'react-redux';
import {Button} from 'reactstrap';
import Opening from './opening';

const convertHours = (int) => {
  let base = Math.floor(int / 60);
  if (base > 12) base = base - 12;
  return base > 0 ? base + '' : '12';
};
const convertMins = int => `0${int % 60}`.replace(/\d(\d\d)/, '$1');

const convertTime = (time) => `${convertHours(time)}:${convertMins(time)}${time >= (12 * 60) ? 'P' : 'A'}M`;

class Day extends React.Component {
  state = {opening: null};

  addNew() {
    const {property: {id}, wday} = this.props;
    const opening = {showing_slots: 1, start_time: 540, end_time: 1020, property_id: id, wday};
    this.setState({...this.state, opening});
  }

  editOpening(opening) {
    this.setState({...this.state, opening});
  }

  close() {
    this.setState({...this.state, opening: null});
  }

  render() {
    const {openings} = this.props;
    openings.sort((a, b) => a.start_time - b.start_time);
    const {opening} = this.state;
    return <td className="p-0" style={{height: 150}}>
      <div className="h-100 d-flex flex-column justify-content-between">
        <div className="py-3">
          {openings.map(o => {
            return <a key={o.id}
                      className="mb-1 d-block text-center badge-info text-white p-1 position-relative"
                      style={{fontSize: '12px'}}
                      onClick={this.editOpening.bind(this, o)}>
              {convertTime(o.start_time)} - {convertTime(o.end_time)}
              <span className="badge badge-danger position-absolute rounded-circle"
                    style={{top: -4, right: -1}}>
                {o.showing_slots}
              </span>
            </a>
          })}

        </div>
        <Button color="success"
                size="sm"
                className="rounded-0"
                outline
                block
                onClick={this.addNew.bind(this)}>
          New
        </Button>
      </div>
      {opening && <Opening opening={opening} toggle={this.close.bind(this)}/>}
    </td>;
  }
}

export default connect(({property}) => {
  return {property};
})(Day);