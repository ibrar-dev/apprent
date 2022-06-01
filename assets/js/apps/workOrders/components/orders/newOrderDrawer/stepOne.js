import React, {useEffect, useState} from "react";
import {
  Select, Input, Button, Statistic, List, Progress, Row, Col, Form,
} from "antd";
import {CheckCircleTwoTone} from "@ant-design/icons";
import axios from "axios";

const mlURL = "/api/notes?getUpdatedCat&note=";

const matchCategoriesToResult = (categories, result) => {
  if (!result || !result.length || !categories || !categories.length) return [];
  return result.map((r) => {
    const cat = categories.find((c) => Number(r.displayName) === c.id);
    return {...cat, ...r};
  });
};

const recommendedRenderer = (c, addAttribute, order) => (
  <List.Item
    onClick={() => addAttribute({category_id: c.id, category: `${c.parent} - ${c.name}`})}
    className="cursor-pointer"
    extra={(
      <CheckCircleTwoTone
        twoToneColor={order.category_id === c.id ? "#5dbd77" : "#d9d9d9"}
        style={{fontSize: 36}}
        type="link"
        shape="circle"
      />
    )}
  >
    <Row className="w-75">
      <Col span={24}>
        <Statistic title={c.parent} value={c.name} />
        <small>Confidence Level</small>
        <Progress
          strokeColor={{"0%": "#108ee9", "35%": "#87d068"}}
          percent={Math.ceil(c.classification.score * 100)}
        />
      </Col>
    </Row>
  </List.Item>
);

const canProceed = ({category_id, note}) => (
  category_id && note && note.length >= 5
);

const StepOne = ({addAttribute, categories, setCurrent, order}) => {
  const [note, setNote] = useState(order.note || "");
  const [recommended, setRecommended] = useState([]);
  const [fetching, setFetching] = useState(false);
  const [fetched, setFetched] = useState(false);

  useEffect(() => {
    const trimmedNote = note.replace(/^\s+/, '').replace(/\s+$/, '');
    if (note.length >= 2 && trimmedNote.length >= 2) {
      const handler = setTimeout(async () => {
        setFetching(true);
        const result = await axios(`${mlURL}${note}`);
        setRecommended(matchCategoriesToResult(categories, result.data));
        setFetching(false);
        setFetched(true);
      }, 750);
      addAttribute({note});
      return () => clearTimeout(handler);
    }
  }, [note]);

  return (
    <Row className="w-100 mt-3">
      <Col span={24} className="w-100">
        <Form.Item validateStatus={note.length < 5 ? "error" : ""} help={note.length < 5 ? "Must be at least 5 letters." : ""}>
          <Input.TextArea
            autoSize
            className="w-100"
            value={note}
            defaultValue={order.note}
            onChange={(e) => setNote(e.target.value)}
          />
        </Form.Item>
        <List
          title="Suggested Categories"
          loading={fetching}
          dataSource={recommended}
          renderItem={(c) => recommendedRenderer(c, addAttribute, order)}
        />
        <Select
          className="w-100 mt-2"
          value={order.category_id}
          disabled={recommended.length <= 0 && !fetched}
          onChange={(c) => addAttribute({category_id: c})}
        >
          {
            categories.map((c) => (
              <Select.Option key={c.id} value={c.id} label={c.name} field={`${c.parent}-${c.name}`} className="mt-1">
                <span><small>{c.parent} - </small><b>{c.name}</b></span>
              </Select.Option>
            ))}
        </Select>
      </Col>
      <Button className="ml-auto mt-3" disabled={!canProceed(order)} onClick={() => setCurrent(1)}>Next</Button>
    </Row>
  );
};

export default StepOne;
