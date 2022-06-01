import React, {useState, useEffect} from "react";
import {Row, Col, Space} from "antd";
import {LoadingOutlined, QuestionCircleTwoTone} from "@ant-design/icons";
import {connect} from "react-redux";
import TagsInput from "react-tagsinput";
import {Popover, PopoverBody, PopoverHeader} from "reactstrap";
import filterOrders from "./filterOrders";
import Unassigned from "./statusPanes/unassigned";
import Assigned from "./statusPanes/assigned";
import Completed from "./statusPanes/completed";
import Cancelled from "./statusPanes/cancelled";

function maxTotal(amount) {
  if (!amount) return 0;
  if (amount > 999) return "999+";
  return amount;
}

const StatusTabs = ({skeleton, dates, newOrders, newOrderDrawer}) => {
  const [tags, setTags] = useState([]);
  const [tab, setTab] = useState("unassigned");
  const [visible, setVisible] = useState(false);

  // Parse search params - /orders?search=foo,bar,baz -> ["foo", "bar", "baz"]
  // Happens only on initial page load
  useEffect(() => {
    const query = new URLSearchParams(window.location.search);
    const urlTags = query.get("search");

    // This works for literal commas in the URL and also for %2C which is the
    // url-escaped comma
    if (urlTags) return setTags(urlTags.split(","));
  }, []);

  // Happens on each tag change - update URL search params to match tags.
  // `value` is an array of strings representing tags in the search box
  const onTagChange = (tagz) => {
    const query = new URLSearchParams(window.location.search);

    // Update the "search" portion of the URL query string
    query.set("search", tagz);

    // Update the URL in place. This doesn't cause a page reload. Commas show up
    // as `%2C` in the URL
    window.history.replaceState({}, "", `${location.pathname}?${query}`);

    setTags(tagz);
  };

  const filtered = filterOrders(newOrders, tags, dates);

  return (
    <div className="w-100">
      <Row justify="space-between">
        <Col>
          <Row gutter={16}>
            <Col>
              <div
                role="none"
                onClick={() => (setTab("unassigned"))}
                style={{fontSize: 16}}
                className={`cursor-pointer badge border badge-pill alert-${tab === "unassigned" ? "success border-success" : "light border-secondary"}`}
              >
                <Space size="small">
                  <i className="fas fa-user-times" style={{color: "#f0ad4e"}} />
                  Unassigned
                  {
                    !skeleton
                    && (
                      <div className="badge badge-danger">
                        {maxTotal(filtered.unassigned.length)}
                      </div>
                    )
                  }
                  {skeleton && <LoadingOutlined spin style={{color: "#5bc0de"}} />}
                </Space>
              </div>
            </Col>
            <Col>
              <div
                role="none"
                onClick={() => (setTab("assigned"))}
                style={{fontSize: 16}}
                className={`cursor-pointer badge border badge-pill alert-${tab === "assigned" ? "success border-success" : "light border-secondary"}`}
              >
                <Space size="small">
                  <i className="fas fa-user" style={{color: "#5bc0de"}} />
                  Assigned
                  {
                    !skeleton
                    && (
                      <div className="badge badge-danger">
                        {maxTotal(filtered.assigned.length)}
                      </div>
                    )
                  }
                  {skeleton && <LoadingOutlined spin style={{color: "#5bc0de"}} />}
                </Space>
              </div>
            </Col>
            <Col>
              <div
                role="none"
                onClick={() => (setTab("completed"))}
                style={{fontSize: 16}}
                className={`cursor-pointer badge border badge-pill alert-${tab === "completed" ? "success border-success" : "light border-secondary"}`}
              >
                <Space size="small">
                  <i className="far fa-check-square" style={{color: "#5cb85c"}} />
                  Completed
                  {
                    !skeleton
                    && (
                      <div className="badge badge-danger">
                        {maxTotal(filtered.completed.length)}
                      </div>
                    )
                  }
                  {skeleton && <LoadingOutlined spin style={{color: "#5bc0de"}} />}
                </Space>
              </div>
            </Col>
            <Col>
              <div
                role="none"
                onClick={() => (setTab("cancelled"))}
                style={{fontSize: 16}}
                className={`cursor-pointer badge border badge-pill alert-${tab === "cancelled" ? "success border-success" : "light border-secondary"}`}
              >
                <Space size="small">
                  <i className="far fa-window-close" style={{color: "#d9534f"}} />
                  Cancelled
                  {
                    !skeleton
                    && (
                      <div className="badge badge-danger">
                        {maxTotal(filtered.cancelled.length)}
                      </div>
                    )
                  }
                  {skeleton && <LoadingOutlined spin style={{color: "#5bc0de"}} />}
                </Space>
              </div>
            </Col>
          </Row>
        </Col>
        <Col>
          <div className="input-group d-flex mb-1">
            <TagsInput
              value={tags}
              onChange={onTagChange}
              onlyUnique
              className="react-tagsinput"
              inputProps={
                {
                  className: "react-tagsinput-input",
                  placeholder: "Add a search term", style: {width: "auto"},
                }
              }
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
      <Row className="w-100">
        {tab === "unassigned" && <Unassigned orders={filtered ? filtered.unassigned : []} newOrderDrawer={newOrderDrawer} dates={dates} />}
        {tab === "assigned" && <Assigned orders={filtered ? filtered.assigned : []} newOrderDrawer={newOrderDrawer} dates={dates} />}
        {tab === "completed" && <Completed orders={filtered ? filtered.completed : []} newOrderDrawer={newOrderDrawer} dates={dates} />}
        {tab === "cancelled" && <Cancelled orders={filtered ? filtered.cancelled : []} newOrderDrawer={newOrderDrawer} dates={dates} />}
      </Row>
    </div>
  );
};

export default connect(({skeleton}) => ({skeleton}))(StatusTabs);
