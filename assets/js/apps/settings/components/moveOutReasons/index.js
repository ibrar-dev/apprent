import React from 'react';
import {connect} from 'react-redux';
import {Input} from 'reactstrap';
import Pagination from '../../../../components/pagination';
import MoveOutReason from './moveOutReason';
import NewMoveOutReason from './newMoveOutReason';

const headers = [
  {label: '', min: true},
  {label: "Name", sort: 'name'}
];

class MoveOutReasons extends React.Component {
  state = {filter: ''};

  _filters() {
    const {filter} = this.state;
    const _this = this;
    return <Input value={filter} onChange={({target: {value}}) => _this.setState({filter: value})}/>
  }

  newMoveOutReason() {
    this.setState({newMoveOutReason: !this.state.newMoveOutReason});
  }

  render() {
    const {moveOutReasons} = this.props;
    const {filter: filterVal, newMoveOutReason} = this.state;
    const filter = new RegExp(filterVal, 'i');
    return <>
      <Pagination component={MoveOutReason}
                  collection={moveOutReasons.filter(b => filter.test(b.name))}
                  title="Move Out Reasons"
                  headers={headers}
                  filters={this._filters()}
                  field="moveOutReason"
                  menu={[
                    {title: 'New Move Out Reason', onClick: this.newMoveOutReason.bind(this)}
                  ]}
                  className="h-100 border-left-0 rounded-0"/>
      {newMoveOutReason && <NewMoveOutReason toggle={this.newMoveOutReason.bind(this)}/>}
    </>;
  }
}

export default connect(({moveOutReasons}) => {
  return {moveOutReasons};
})(MoveOutReasons);