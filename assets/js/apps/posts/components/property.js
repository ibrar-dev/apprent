import React, {Component, Fragment} from 'react';
import {connect} from 'react-redux';
import Pagination from '../../../components/pagination';
import Post from './post';
import {Input} from "reactstrap";
import 'react-dates/initialize';
import {DateRangePicker} from "react-dates";
import isInclusivelyAfterDay from "react-dates/lib/utils/isInclusivelyAfterDay";
import moment from "moment";
import InfoModal from './infoModal';

const headers = [
  {label: '', min: true},
  {label: "Resident", sort: 'name'},
  {label: "Post", sort: 'text'},
  {label: "Date", sort: 'inserted_at'},
  {label: "Likes", sort: 'likesCount'},
  {label: "Reports", sort: 'reportsCount'}
];

class Property extends Component {
  state = {
    startDate: moment().subtract(30, 'days'),
    endDate: moment(),
    filterVal: ''
  }

  updateCalendar({startDate, endDate}) {
    this.setState({...this.state, startDate, endDate})
  }

  changeFilter(e) {
    this.setState({...this.state, filterVal: e.target.value});
  }

  _filters() {
    const {filterVal, startDate, endDate, focusedInput} = this.state;
    return <Fragment>
      <DateRangePicker startDate={startDate}
                       endDate={endDate}
                       startDateId="start-timecard-date-id"
                       endDateId="end-timecard-date-id"
                       focusedInput={focusedInput}
                       minimumNights={0}
                       small
                       isOutsideRange={day => isInclusivelyAfterDay(day, moment().add(1, 'days'))}
                       onFocusChange={focusedInput => this.setState({focusedInput})}
                       onDatesChange={this.updateCalendar.bind(this)}/>
      <Input value={filterVal} placeholder="Resident or Post" onChange={this.changeFilter.bind(this)}/>
    </Fragment>
  }

  filterPosts(posts) {
    const {filterVal, startDate, endDate} = this.state;
    const filter = new RegExp(filterVal, 'i');
    return posts.filter(p => moment.utc(p.inserted_at).local().isBetween(moment(startDate).startOf('day'), endDate) && (filter.test(p.resident) || filter.test(p.text)))
  }

  setInfoPost(post) {
    this.setState({...this.state, post: post})
  }

  render() {
    const {property, posts} = this.props;
    const {post} = this.state;
    return <Fragment>
      <Pagination component={Post}
                  collection={this.filterPosts(posts)}
                  title={<div>{property.name} Resident Social Media Posts</div>}
                  headers={headers}
                  filters={this._filters()}
                  additionalProps={{setPost: this.setInfoPost.bind(this)}}
                  field="post"
                  className="h-100 border-left-0 rounded-0"/>
      {post && <InfoModal post={post} toggle={this.setInfoPost.bind(this, null)} />}
    </Fragment>
  }
}

export default connect(({posts}) => {
  return {posts}
})(Property)
