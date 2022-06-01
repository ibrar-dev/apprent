import React from "react";
import {Button} from 'reactstrap';
import TagsInput from 'react-tagsinput';
import moment from 'moment';
import Page from "./page";
import PageForm from "./pageForm";
import Pagination from "../../../components/pagination";
import {safeRegExp} from "../../../utils";
import actions from '../actions';

const headers = [
  {label: '', min: true},
  {label: 'Date', sort: 'date', min: true},
  {label: 'Notes'},
  {label: 'Total'},
  {label: ''}
];

class Pages extends React.Component {
  state = {
    tags: []
  };

  tagChange(tags) {
    this.setState({...this.state, tags})
  }

  _filters() {
    const {tags} = this.state;
    return <TagsInput value={tags} onChange={this.tagChange.bind(this)} onlyUnique inputProps={{className: 'react-tagsinput-input w-100', placeholder: 'Add a search tag'}} />
  }

  filtered() {
    const {tags} = this.state;
    const {journalPages} = this.props;
    const filtered = journalPages.filter(p => this.checkFilter(p, tags));
    return filtered;
  }

  checkFilter(page, tags) {
    if (!tags || tags.length === 0) return true;
    const checked = tags.map(t => this.checkTag(page, t));
    return checked.every(t => t ===  true);
  }

  checkTag(page, tag) {
    const filter = safeRegExp(tag);
    if (filter.test(page.name) || filter.test(page.total) || filter.test(page.date) || this.checkDate(page.date, filter)) return true;
    if (this.checkEntries(page.entries || [], filter)) return true;
    return false;
  }

  checkEntries(entries, filter) {
    const filtered = entries.map(p => {
      return (filter.test(p.property) || filter.test(p.account) || filter.test(p.amount))
    })
    return filtered.some(t => t === true);
  }

  checkDate(date, filter) {
    return (filter.test(date) || filter.test(moment(date).format("MM/DD/YYYY")));
  }

  newEntry() {
    actions.editPage(this.props.editing ? null : {});
  }

  render() {
    const {journalPages, editing} = this.props;
    return editing ? <PageForm toggle={this.newEntry.bind(this)} page={editing}/> :
      <Pagination collection={this.filtered()}
                  component={Page}
                  title={<div>Journal Entries<Button size="sm" className="ml-3"
                                              color="success" onClick={this.newEntry.bind(this)}>
                    New Entry
                  </Button></div>}
                  headers={headers}
                  filters={this._filters()}
                  field="entry"
      />;
  }
}

export default Pages;