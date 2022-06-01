import React from 'react';
import {Card, CardHeader, CardBody} from 'reactstrap';
import TagsInput from 'react-tagsinput';
import MemoModal from '../memoModal';
import {Table} from 'antd'
import moment from 'moment';

const columns = [
  {
    title: 'Memo',
    dataIndex: 'id',
    key: 'id',
    render: (id, record) => (
      <div key={id}>
        <b className="mr-2">
          <span className="mr-2">{moment(record.inserted_at).format('M/D')}</span>
          {record.admin_name}:
        </b>
        <div className="ml-2">
          {record.note}
        </div>
      </div>
    ),
  }
]

class MemoCard extends React.Component {
  constructor(props) {
  super(props);
    this.state = {
      tags: [],
    };
    this.tagChange = this.tagChange.bind(this);
    this.filterMemos = this.filterMemos.bind(this);
  }

  tagChange(tags) {
    this.setState({...this.state, tags})
  }

  filterMemos(memos, tags) {
    return memos.filter(({note, admin_name}) => {
      return (
        tags.some(tag => note.toLowerCase().includes(tag.toLowerCase()))
        || tags.some(tag => admin_name.toLowerCase().includes(tag.toLowerCase()))
      )
    });
  }

  render() {
    const {onClose, onOpen, application, currentModal} = this.props;
    const {tags} = this.state;
    const {memos} = application
    const filtered = tags && tags.length > 0 ? this.filterMemos(memos, tags) : memos;
    const sortedMemos = filtered.slice().sort((a, b) => b.id - a.id);
    const tableData = sortedMemos.map(mem => ({...mem, key: mem.id}))
    return (
      <Card>
        {
          currentModal === 'memo'
          && <MemoModal toggle={onClose} applicationId={application.id} />
        }
        <CardHeader className="d-flex justify-content-between">
          <div>Memos</div>
          <a onClick={onOpen}>ADD</a>
        </CardHeader>
        <CardBody>
          {
            application.memos
            && application.memos.length > 2
            && (
              <TagsInput
                value={tags}
                onChange={this.tagChange}
                onlyUnique
                className="react-tagsinput flex-fill mb-2"
                inputProps={{
                  className: 'react-tagsinput-input',
                  placeholder: 'Add a search term', style: {width: 'auto'}
                }}
              />
            )
          }
          <Table
            showHeader={false}
            columns={columns}
            pagination={{
              size: "small",
              position: ["bottomCenter"],
              hideOnSinglePage: true,
              pageSize: 2,
              showTotal: total => `${total} Memos`,
            }}
            dataSource={tableData}
          />
        </CardBody>
      </Card>
    )
  }
}

export default MemoCard;
