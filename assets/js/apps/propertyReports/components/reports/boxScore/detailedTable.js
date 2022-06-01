import React, {useState} from 'react';
import {Table, Input, Button, Space} from 'antd';
import { SearchOutlined, CloseOutlined } from '@ant-design/icons';
import {connect} from 'react-redux';
import {titleize} from "../../../../../utils";
import actions from '../../../actions';

const columns = [
  {title: "Unit Number", dataIndex: 'number', key: 'number', filter: "number"},
  {title: "Status", dataIndex: 'status', key: 'status'},
  {title: "Lease End", dataIndex: 'lease_end', key: 'lease_end'},
  {title: "Move Out", dataIndex: 'move_out_date', key: 'move_out_date'}
];

const filteredColumn = (field) => {
  const [val, setVal] = useState('');

  function resetFilters(clearFilters) {
    clearFilters();
    setVal('');
  }

  function handleSearch(selectedKeys, confirm, dataIndex) {
    confirm();
  }

  return {
    filtered: true,
    filterDropdown: ({setSelectedKeys, selectedKeys, confirm, clearFilters}) => {
      return <div style={{padding: 8}}>
        <Input style={{ width: 188, marginBottom: 8, display: 'block' }}
               value={selectedKeys[0]}
               placeholder={`Search ${titleize(field)}`}
               onPressEnter={() => handleSearch(selectedKeys, confirm, field)}
               onChange={e => setSelectedKeys(e.target.value ? [e.target.value] : [])}
        />
        <Space>
          <Button type={"primary"}
                  icon={<SearchOutlined />}
                  style={{ width: 90 }}
                  onClick={() => handleSearch(selectedKeys, confirm, field)}>Search</Button>
          <Button onClick={() => resetFilters(clearFilters)}
                  style={{ width: 90 }} >Clear</Button>
        </Space>
      </div>
    },
    filterIcon:  <SearchOutlined />,
    onFilter: (val, record) => {
      const regexFilter = new RegExp(val, 'i');
      return record[field].match(regexFilter)
    }
  }
};

function mergedColumns() {
  return columns.map(c => {
    if (c.filter) {
      return {...c, ...filteredColumn(c.filter)}
    } else {
      return c
    }
  })
}

function DetailedTable({detailed: {data: {units, count}, title}}) {
  return <Table dataSource={units}
                size={"middle"}
                title={() => <div className="d-flex justify-content-between">
                  <span>{title}</span>
                  <Button size={"small"} type={"link"} onClick={() => actions.setDetailedData(null)} >
                    <CloseOutlined />
                  </Button>
                </div>}
                columns={mergedColumns()}
                rowKey={u => u.id} />
}

export default connect(({detailed}) => {
  return {detailed}
})(DetailedTable)
