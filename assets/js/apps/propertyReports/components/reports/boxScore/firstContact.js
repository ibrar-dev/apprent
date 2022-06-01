import React from 'react';
import {Table, Space, Skeleton, Button} from 'antd';
import {DollarCircleOutlined, FileSearchOutlined, HomeOutlined} from "@ant-design/icons";
import TagsInput from 'react-tagsinput';
import moment from 'moment';
import {connect} from "react-redux";
import {safeRegExp, toCurr} from "../../../../../utils";
import {sortableStringColumn, currencyRenderer, dateRenderer} from "./functions";
const columns = [
  {title: 'View', render: payment => (actionRenderer(payment))},
  {title: "Applicant", dataIndex: 'persons', render: persons => (personRenderer(persons))},
  {title: "Amount", simpleSort: true, dataIndex: 'amount', render: num => (currencyRenderer(num))},
  {title: "Date", dataIndex: 'date', render: date => (dateRenderer(date))},
  {title: "Transaction ID", simpleSort: true, dataIndex: 'transaction_id'},
  {title: "Description", dataIndex: 'description', render: r => (descriptionRenderer(r))},
  {title: "Last 4", dataIndex: 'response', render: r => (responseRenderer(r))}
];

function mergedColumns() {
  return columns.map(c => {
    if (c.simpleSort) {
      return {...c, ...sortableStringColumn(c.dataIndex)}
    } else {
      return c
    }
  })
}

function descriptionRenderer(descriptions) {
  return(
    <ul className="list-unstyled">
      {descriptions.sort((a,b) => a < b ? 1 : -1).map((desc) =>
        <li key={desc}>{desc}</li>
      )}
    </ul>
  )
}

function actionRenderer(payment) {
  return <Space size={"small"}>
    <Button
      type={"link"}
      icon={<DollarCircleOutlined/>}
      href={`/payments/${payment.id}`}
      target={"_blank"}
    />
    {payment.application_id && <Button
      type={"link"}
      icon={<FileSearchOutlined/>}
      href={`/applications/${payment.application_id}`}
      target={"_blank"}
    />}
    {payment.tenant_id && <Button
      type={"link"}
      icon={<HomeOutlined/>}
      href={`/tenants/${payment.tenant_id}`}
      target={"_blank"}
    />}
  </Space>
}

function responseRenderer(response) {
  if (!response["account_number"]) return "";
  return <span>{response["account_number"]}</span>
}

function personRenderer(persons) {
  return <Space size={"small"} direction={"vertical"}>
    {persons && persons.map(p => (<span>{p.full_name}</span>))}
  </Space>
}

function filterTags(data, tags) {
  return data.filter(p => checkTags(p, tags))
}

function checkTags(payment, tags) {
  if (!tags || tags.length === 0) return true;
  const checked = tags.map(t => checkTag(payment, t));
  return checked.every(t => t === true);
}

function checkTag(payment, tag) {
  const filter = safeRegExp(tag);
  return (
    filter.test(payment.amount) ||
    checkDate(payment, filter) ||
    checkPersons(payment, filter) ||
    filter.test(payment.transaction_id) ||
    checkCard(payment, filter) ||
    filter.test(payment.description)
  );
}

function checkPersons({persons, payer}, filter) {
  const filtered = persons.filter(p => filter.test(p.full_name));
  return filtered.length >= 1 || filter.test(payer);
}

function checkCard({response}, filter) {
  if (!response) return false;
  return filter.test(response["account_number"])
}

function checkDate({date}, filter) {
  return filter.test(moment(date).format("MM/DD/YYYY"))
}

function summary(report) {
  if (!report) return <Table.Summary.Row />
  const totals = report.reduce((acc, p) => {
    let app_ids = acc.application_ids;
    let unknowns = acc.unknowns;
    if (p.application_id && !acc.application_ids.includes(p.application_id)) {
      app_ids.push(p.application_id);
    } else if (!p.application_id) {
      unknowns.push(p.application_id);
    }
    return {amount: eval(`${p.amount} + ${acc.amount}`), application_ids: app_ids, unknowns: unknowns}
  }, {amount: 0, application_ids: [], unknowns: []});
  return (
    <Table.Summary.Row>
      <Table.Summary.Cell />
      <Table.Summary.Cell><b>Totals:</b></Table.Summary.Cell>
      <Table.Summary.Cell><b>{toCurr(totals.amount)}</b></Table.Summary.Cell>
      <Table.Summary.Cell><b>Applications:</b></Table.Summary.Cell>
      <Table.Summary.Cell><b>{totals.application_ids.length}</b></Table.Summary.Cell>
      <Table.Summary.Cell><b>Unknown Payments</b></Table.Summary.Cell>
      <Table.Summary.Cell><b>{totals.unknowns.length}</b></Table.Summary.Cell>
    </Table.Summary.Row>
  )
}

class FirstContactReport extends React.Component {
  state = {
    tags: [],
    pageSize: 25,
  };
  tagChange(tags) {
    this.setState({...this.state, tags});
  }

  title() {
    const {dates} = this.props;
    const {tags} = this.state;
    return <div className={"d-flex justify-content-between"}>
      <span>{`Applicant Payments Received ${dates[0].format("MM/DD/YY")} - ${dates[1].format("MM/DD/YY")}`}</span>
      <span>
        <TagsInput
          value={tags}
          onChange={this.tagChange.bind(this)}
          onlyUnique className="react-tagsinput flex-fill"
          inputProps={{className: 'react-tagsinput-input', placeholder: 'Add a search term', style: {width: 'auto'}}}
        />
      </span>
    </div>
  }

  pageSizeOptions = (total) => ([10, 20, 50, 100].filter((x) => x < total).concat([total]));
  render() {
    const {skeleton, reportData} = this.props;
    const {tags, pageSize} = this.state;
    if (skeleton || reportData.floor_plans) {
      return <Skeleton active={true} paragraph={{paragraph: 10, width: '100%'}} />
    }
    const data = filterTags(reportData, tags);
    return <div className={"w-100"}>
      <Space className={"w-100"} size={"large"} direction={"vertical"}>
        <Table
          className={"w-100"}
          dataSource={data}
          size={"middle"}
          rowKey={p => p.id}
          bordered
          summary={data => summary(data)}
          pagination={{
            showSizeChanger: true,
            defaultPageSize: data.length,
            pageSizeOptions: this.pageSizeOptions(data.length),
            position: ['topRight'],
          }}
          title={() => this.title()}
          columns={mergedColumns()}
        />
      </Space>
    </div>
  }
}

export default connect(({reportData, skeleton}) => {
  return {reportData, skeleton}
})(FirstContactReport)
