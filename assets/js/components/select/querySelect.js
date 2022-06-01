import React from 'react';
import Select from './index';

class QuerySelect extends React.Component {
  timer = null;
  state = {options: this.props.defaultOptions || [], filter: ''};

  changeFilter(filterVal) {
    const {filter} = this.state;
    const {search, transform} = this.props;
    if (filterVal !== filter && filterVal.length > 2) {
      this.setState({filter: filterVal, options: []});
      if (this.timer) clearTimeout(this.timer);
      this.timer = setTimeout(() => {
        this.setState({loading: true});
        this.timer = null;
        search(filterVal).then(results => {
          this.setState({loading: false, options: transform ? transform(results) : results});
        });
      }, 1200);
    }
  }

  render() {
    const {options, loading} = this.state;
    return <Select {...this.props}
                   isLoading={loading}
                   noOptionsMessage={() => loading ? 'Loading...' : 'No Options'}
                   onInputChange={this.changeFilter.bind(this)}
                   options={options}/>;
  }
}

export default QuerySelect;