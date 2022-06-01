import React from 'react';
import Account from './account';
import Category from './category';

class Entry extends React.Component {
  render() {
    const {entry, categories} = this.props;
    if (entry.type === 'category' || entry.type === 'total') return <Category category={entry}/>;
    return <Account account={entry} categories={categories}/>
  }
}

export default Entry;