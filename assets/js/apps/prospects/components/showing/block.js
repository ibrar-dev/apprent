import React from 'react';
import moment from 'moment';
import Select from '../../../../components/select';
import classnames from 'classnames';
import actions from "../../actions";

class Block extends React.Component {
  state = {
    end_time: ''
  }

  addShowing({target: {value}}) {
    const {date, prospect, start, setError, setPending} = this.props;
    const formattedDate = moment(date).format('YYYY-MM-DD');
    setPending(true);
    const promise = actions.createShowing({
      prospect_id: prospect.id,
      start_time: start,
      end_time: start + value,
      date: formattedDate
    });
    promise.then(r => {
      setPending(false);
    });
    promise.catch(e => {
      setPending(false);
      setError(e.response.data.error);
    });
  }

  cancel() {
    if (confirm('Cancel this showing?')) {
      actions.deleteShowing(this.props.showing);
    }
  }

  render() {
    const {showing, start, interval, available} = this.props;
    const {end_time} = this.state;
    const styling = {
      'border-bottom-0': showing && showing.end_time > start + interval,
      'border-top-0': showing && showing.start_time < start,
      'bg-info text-white': showing,
      'text-center clickable align-middle min-react-select': true
    };
    return <td className={classnames(styling)}>
      {showing && showing.start_time === start && <div className="d-flex justify-content-between">
        <div>{showing.prospect}</div>
        <a onClick={this.cancel.bind(this)}>
          <i className="fas fa-times text-white"/>
        </a>
      </div>}
      {!showing && available && <div>
        <Select value=""
                searchable={false}
                placeholder="Schedule showing"
                arrowRenderer={() => {
                }}
                options={[
                  {value: 30, label: '30 minutes'},
                  {value: 60, label: '1 hour'},
                  {value: 90, label: '1.5 hours'},
                  {value: 120, label: '2 hours'},
                ]}
                onChange={this.addShowing.bind(this)}/>
        {end_time && <h5>Hello World</h5>}
      </div>}
      </td>
      }
      }

      export default Block;