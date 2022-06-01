import React, {useState, useEffect} from "react";
import {connect} from "react-redux";
import {
  Tooltip, Popover, PopoverBody, PopoverHeader,
} from "reactstrap";
import moment from "moment";
import TagsInput from "react-tagsinput";
import {
  Card, Button, Row, Col, Space, DatePicker
} from "antd";
import {QuestionCircleTwoTone} from "@ant-design/icons";
import Pagination from "../../../components/pagination";
import {
  isUser, safeRegExp, toCurr, currentUserId
} from "../../../utils";
import actions from "../actions";
import ApprovalLineItem from "./approvalLineItem";
import MultiPropertySelect from "../../../components/multiPropertySelect";

const {RangePicker} = DatePicker;
const dateFormats = ["MM/DD/YY", "MM/DD/YYYY", "MM-DD-YY", "MM-DD-YYYY"];
const {properties} = window;

const dateSort = (a1, a2) => {
  const d1 = (new Date(a1.inserted_at)).getTime();
  const d2 = (new Date(a2.inserted_at)).getTime();
  return d1 - d2;
};

const headers = [
  {label: "Vendor"},
  {label: "Requestor"},
  {label: "Date", sort: dateSort},
  {label: "Unit"},
  {label: "PO Number", sort: "num"},
  {label: "Costs"},
  {label: "Amount"},
  {
    label: (
      <span id="status-tooltip">
        Status
        {" "}
        <i className="fas fa-question-circle" />
      </span>
    ),
  },
];

const Approvals = ({approvals, payees, propertiesSelected, history}) => {
  const [tags, setTags] = useState([]);
  const [dates, setDates] = useState([null, null]);

  const [tooltip, setTooltip] = useState(false);
  const [sort, setSort] = useState("pending");
  const [mineSub, setMineSub] = useState("pending");
  const [visible, setVisible] = useState(false);

  useEffect(() => {
    actions.fetchApprovals();
  }, [propertiesSelected]);

  const getApprovers = (logs) => {
    if (!logs.length) return [];
    return logs.filter((l, i, a) => a.map((x) => x.admin_id).indexOf(l.admin_id) === i);
  };

  const getApproverStatus = (logs, admin_id) => {
    const sortedLogs = logs.sort((a, b) => moment(b.inserted_at) - moment(a.inserted_at));
    const mostRecent = sortedLogs.filter((l) => l.admin_id === admin_id)[0];
    if (!mostRecent) return "warning";
    const {status} = mostRecent;
    if (status === "Approved") return "success";
    if (status === "Declined") return "danger";
    if (status === "More Info Requested") return "warning";
    return "info";
  };

  const fullyApproved = (logs) => {
    if (!logs || !logs.length) return false;
    const approvers = getApprovers(logs);
    return approvers.every((a) => getApproverStatus(logs, a.admin_id) === "success");
  };

  const checkIfCancelled = (logs) => {
    if (!logs || !logs.length) return false;
    if (
      logs.filter((l) => l.status === "Cancelled"
      || l.status === "Declined"
      || l.status === "Denied").length >= 1
    ) return true;
    return false;
  };

  const inLogs = (logs) => (logs.filter((l) => isUser(l.admin_id)).length >= 1);

  const checkUserStatus = (a) => {
    let status;
    if (a.logs && a.logs.length) {
      status = getApproverStatus(a.logs, currentUserId());
    }
    return status && status === "info";
  }

  const sortedList = (list) => {
    const sorted = {
      pending: [], approved: [], declined: [], invoiced: [], mine: {pending: [], all: []}
    };
    if (!list || !list.length) return sorted;
    list.forEach((a) => {
      if (checkIfCancelled(a.logs)) return sorted.declined.push(a);
      if (isUser(a.requestor.id) || inLogs(a.logs)) {
        sorted.mine.all.push(a);
        if (checkUserStatus(a)) {
          sorted.mine.pending.push(a);
        }
      }
      if (a.params && a.params.invoice_date) return sorted.invoiced.push(a);
      if (fullyApproved(a.logs)) return sorted.approved.push(a);
      return sorted.pending.push(a);
    });
    return sorted;
  };

  const checkDates = ({inserted_at}) => {
    const [startDate, endDate] = dates;
    if (startDate && endDate) return moment.utc(inserted_at).isBetween(startDate, endDate);
    return true;
  };

  const filtered = () => (
    approvals.filter((a) => checkFilter(a, tags) && checkDates(a))
  );

  const checkParams = ({params}, tag) => {
    const filt = safeRegExp(tag);
    if (!params) return false;
    const filteredPayees = payees.filter((p) => filt.test(p.name)).map((p) => p.id);
    const unitRegex = new RegExp(`Unit-${tag}`, "i");
    if (
      checkAmount(params.amount, tag)
      || filteredPayees.includes(params.payee_id)
      || params.description.match(unitRegex)
    ) return true;
    return false;
  };

  const checkApprovers = (logs, tag) => {
    const pattern = safeRegExp("approver:");
    if (pattern.test(tag)) {
      const name = tag.split(pattern)[1].trim();
      const filt = safeRegExp(name);
      return logs.map((l) => filt.test(l.admin)).some((l) => l === true);
    }
    return false;
  };

  const checkCategories = (costs, filt) => {
    const filteredByName = costs.filter((c) => filt.test(c.category_name));
    const filteredByAmount = costs.filter((c) => filt.test(c.amount));
    if (filteredByName.length || filteredByAmount.length) return true;
    return false;
  };

  const checkTag = (approval, tag) => {
    const filt = safeRegExp(tag);
    if (
      filt.test(approval.requestor.name)
      || filt.test(approval.num)
      || filt.test(approval.property)
      || checkParams(approval, tag)
      || checkApprovers(approval.logs || [], tag)
      || checkCategories(approval.costs, filt)
      || filt.test(approval.id)
    ) return true;
    return false;
  };

  const checkFilter = (approval, tagss) => {
    if (!tagss || tagss.length === 0) return true;
    const checked = tagss.map((t) => checkTag(approval, t));
    return checked.every((t) => t === true);
  };

  const checkAmount = (amount, tag) => {
    const filt = safeRegExp(tag);
    const pattern = new RegExp(">");
    if (pattern.test(tag)) {
      const range = tag.split(">");
      return (amount >= parseFloat(range[0]) && amount <= parseFloat(range[1] || "999999.99"));
    }
    return filt.test(amount);
  };

  const totalRow = (list) => {
    const totals = list.reduce((acc, a) => (
      {
        amount: acc.amount + parseFloat(a.params.amount || "0"),
        count: acc.count + 1,
      }
    ), {amount: 0, count: 0});
    return (
      <tr>
        <th className="text-right" colSpan={2}>Totals:</th>
        <th>
          Approvals:
          {" "}
          {totals.count}
        </th>
        <td />
        <td />
        <td />
        <th>{toCurr(totals.amount)}</th>
        <td />
      </tr>
    );
  };

  const sorted = sortedList(filtered());

  const listToDisplay = () => {
    if (sort === "mine") {
      if (mineSub === "pending") return sorted.mine.pending;
      return sorted.mine.all;
    }
    return sorted[sort];
  };

  return (
    <Card className="w-100">
      <Space direction="vertical" size="large" className="w-100">
        <Row justify="space-between">
          <div
            className={
              `d-flex flex-row w-50 border border-success ${properties.length <= 1 ? "invisible" : "visible"}`
              }
            >
            <MultiPropertySelect
              // TODO add loading
              // selectProps={{loading: skeleton, bordered: false}}
              selectProps={{bordered: false}}
              className="flex-fill"
              onChange={(p) => actions.setPropertiesSelected(p)}
            />
          </div>
          <div className="d-flex flex row border border-secondary" style={{zIndex: "3"}}>
            <RangePicker
              allowClear={false}
              value={dates}
              bordered={false}
              format={dateFormats}
              onChange={setDates}
            />
          </div>
        </Row>
        <div className="w-100">
          <Row justify="space-between">
            <Col>
              <Row gutter={16}>
                <Col>
                  <Button
                    onClick={() => setSort("approved")}
                    type={sort === "approved" ? "primary" : "text"}
                  >
                    {sorted.approved.length}
                    {" "}
                    Approved
                  </Button>
                </Col>
                <Col>
                  <Button
                    onClick={() => setSort("pending")}
                    type={sort === "pending" ? "primary" : "text"}
                  >
                    {sorted.pending.length}
                    {" "}
                    Pending
                  </Button>
                </Col>
                <Col>
                  <Button
                    onClick={() => setSort("declined")}
                    type={sort === "declined" ? "primary" : "text"}
                  >
                    {sorted.declined.length}
                    {" "}
                    Declined
                  </Button>
                </Col>
                <Col>
                  <Button
                    onClick={() => setSort("invoiced")}
                    type={sort === "invoiced" ? "primary" : "text"}
                  >
                    {sorted.invoiced.length}
                    {" "}
                    Invoiced
                  </Button>
                </Col>
                <Col>
                  <Space
                    direction="vertical"
                    size="small"
                  >
                    <Button
                      onClick={() => setSort("mine")}
                      type={sort === "mine" ? "primary" : "text"}
                    >
                      {sorted.mine.all.length}
                      {" "}
                      Mine
                    </Button>
                    {sort === "mine" && (
                      <Space size="small" direction="horizontal" className="ml-n3">
                        <Button
                          onClick={() => setMineSub("pending")}
                          type={mineSub === "pending" ? "primary" : "text"}
                          size="small"
                        >
                          Pending
                        </Button>
                        <Button
                          onClick={() => setMineSub("all")}
                          type={mineSub === "all" ? "primary" : "text"}
                          size="small"
                        >
                          All
                        </Button>
                      </Space>
                    )}
                  </Space>
                </Col>
              </Row>
            </Col>
            <Col>
              <div className="input-group d-flex mb-1">
                <TagsInput
                  value={tags}
                  onChange={setTags}
                  onlyUnique
                  className="react-tagsinput"
                  inputProps={{
                    className: "react-tagsinput-input",
                    placeholder: "Add a search term",
                    style: {width: "auto"},
                  }}
                />
                <div className="input-group-append" id="search_help_popover">
                  <span className="input-group-text">
                    <QuestionCircleTwoTone style={{fontSize: 16}} twoToneColor="#28a745" />
                  </span>
                </div>
                <Popover
                  placement="right"
                  isOpen={visible}
                  trigger="hover"
                  target="search_help_popover"
                  toggle={() => setVisible(!visible)}
                >
                  <PopoverHeader>Search Help</PopoverHeader>
                  <PopoverBody>
                    <p>
                      You can use the new search bar to the left in many powerful
                      ways. Just type what you want to search for and press enter.
                    </p>
                    <p>
                      You can string as many search terms as you would like, the only
                      work orders that will show up are ones that match up with ALL
                      the search terms.
                    </p>
                    <p>
                      For example to search for all work orders for Unit 1234 with a
                      category of light bulb out, just type 1234 and press enter. Next
                      type light bulb and press enter.
                    </p>
                    <p>
                      To search for all work orders with a 5 star rating from the
                      resident, type 5 stars and press enter.
                    </p>
                  </PopoverBody>
                </Popover>
              </div>
            </Col>
          </Row>
          <Row className="w-100 my-2" justify="end">
            <Button onClick={() => history.push("/approvals/new")}>New Approval</Button>
          </Row>
          <Row className="w-100">
            <Pagination
              className="w-100"
              hidePerPage
              component={ApprovalLineItem}
              field="approval"
              headers={headers}
              tableClasses="table-hover"
              totalRow={totalRow(listToDisplay())}
              collection={listToDisplay()}
            />
            <Tooltip placement="top" isOpen={tooltip} target="status-tooltip" toggle={() => setTooltip(!tooltip)}>
              <p className="alert-success">Approved</p>
              <p className="alert-danger">Declined</p>
              <p className="alert-warning">More Info Needed</p>
              <p className="alert-info">Pending Approval</p>
            </Tooltip>
          </Row>
        </div>
      </Space>
    </Card>
  )
}

export default connect(({approvals, payees, propertiesSelected}) => ({approvals, payees, propertiesSelected}))(Approvals);
