import React from 'react';
import {connect} from 'react-redux';
import {Input} from 'reactstrap';
import Pagination from '../../../../components/pagination';
import Damage from './damage';
import NewDamage from './newDamage';

const headers = [
  {label: '', min: true},
  {label: 'Account', width: 270},
  {label: "Name", sort: 'name'}
];

class Damages extends React.Component {
  state = {filter: ''};

  _filters() {
    const {filter} = this.state;
    const _this = this;
    return <Input value={filter} onChange={({target: {value}}) => _this.setState({filter: value})}/>
  }

  newDamage() {
    this.setState({newDamage: !this.state.newDamage});
  }

  render() {
    const {damages} = this.props;
    const {filter: filterVal, newDamage} = this.state;
    const filter = new RegExp(filterVal, 'i');
    return <>
      <Pagination component={Damage}
                  collection={damages.filter(b => filter.test(b.name))}
                  title="Damages"
                  headers={headers}
                  filters={this._filters()}
                  field="damage"
                  menu={[
                    {title: 'New Damage', onClick: this.newDamage.bind(this)}
                  ]}
                  className="h-100 border-left-0 rounded-0"/>
      {newDamage && <NewDamage toggle={this.newDamage.bind(this)}/>}
    </>;
  }
}

export default connect(({damages}) => {
  return {damages};
})(Damages);