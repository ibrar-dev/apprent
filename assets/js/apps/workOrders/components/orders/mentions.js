import React, {useState, useEffect} from "react";
import {MentionsInput, Mention} from "react-mentions";
import {
  Col, Row, Spin, Button,
} from "antd";
import {SendOutlined} from "@ant-design/icons";
import axios from "axios";
import snackbar from "../../../../components/snackbar";
import Uploader from "../../../../components/uploader";
import actions from "../../actions";
import MentionInstructions from "./mentionInstructions";
import {defaultMentionStyle, defaultStyle} from "../../../../components/mentions/style"

const buildResident = (resident) => (
  resident?.email
    ? {
      id: 0,
      name: `${resident.first_name} ${resident.last_name} (Resident)`,
      email: resident.email,
    }
    : null
);

const Mentions = ({tenant, admins, order, onNewNoteSuccess}) => {
  const [value, setValue] = useState("");
  const [plainText, setPlainText] = useState("");
  const [mentions, setMentions] = useState([]);
  const [isTextNote, setIsTextNote] = useState(true);
  const [submitting, setSubmitting] = useState(false);
  const [attachment, setAttachment] = useState(null);
  const uniqMentions = mentions.filter((v, i) => mentions.findIndex((t) => (t.id === v.id)) === i);
  const resident = buildResident(tenant);
  const everyone = resident ? [resident, ...admins] : [...admins];

  useEffect(() => {
    if (attachment) {
      const upload = attachment.upload();
      upload.then(() => {
        if (attachment.uuid) setValue({attachment: {uuid: attachment.uuid}});
      });
    }
  }, [attachment]);

  const handleChange = (_event, newValue, newPlainTextValue, mmentions) => {
    setValue(newValue);
    setPlainText(newPlainTextValue);
    setMentions(mmentions);
  };

  const submitNote = () => {
    setSubmitting(true);
    const mergedMentions = uniqMentions.map((m) => {
      const {email} = everyone.find((a) => a.id === Number(m.id));
      return {...m, name: m.display, email};
    });
    const base = {order_id: order.id, mentions: mergedMentions, image: null};
    const params = isTextNote ? {...base, text: plainText} : {...base, attachment, image: null};
    const promise = axios.post("/api/notes", {newNote: params});
    promise.then(() => {
      actions.setOrderData(null);
      onNewNoteSuccess();
      snackbar({message: "Note added to order", args: {type: "success"}});
    });
    promise.catch(() => {
      snackbar({message: "Something went wrong", args: {type: "error"}});
    });
    promise.finally(() => setSubmitting(false));
  };

  const disableSubmit = () => {
    const base = submitting || isTextNote;
    return base ? plainText.length <= 5 : !attachment || Object.keys(attachment).length === 0;
  };

  let inputArea;
  if (isTextNote) {
    inputArea = (
      <>
        <MentionInstructions hasValidResident={resident} />
        <MentionsInput
          placeholder="Type your note here"
          value={value}
          allowSpaceInQuery
          onChange={handleChange}
          style={defaultStyle}
        >
          <Mention
            trigger="@"
            displayTransform={(_, display) => `@${display}`}
            data={everyone.map((p) => ({id: p.id, display: `${p.name}`}))}
            markup="@{{__id__||__display__}}"
            style={defaultMentionStyle}
            appendSpaceOnAdd
          />
        </MentionsInput>
      </>
    );
  } else {
    inputArea = (
      <div>
        <p className="text-left mt-1">Upload an attachment.</p>
        <Uploader onChange={setAttachment} />
      </div>
    );
  }

  return (
    <>
      <Row>
        <Col span={24}>
          <Spin spinning={submitting}>
            {inputArea}
          </Spin>
          <Row justify="space-between" className="mt-1">
            <Col className="mt-1">
              {
                isTextNote
                  ? `Mentioning ${uniqMentions.length} ${uniqMentions.length !== 1 ? "people" : "person"}`
                  : ""
              }
            </Col>
            <Col>
              <Button type="link" onClick={() => setIsTextNote(!isTextNote)}>
                {isTextNote ? "Upload an attachment instead" : "Submit a note instead"}
              </Button>
            </Col>
          </Row>
        </Col>
      </Row>
      <Row justify="end" className="mt-2">
        <Col>
          <Button
            type="primary"
            disabled={disableSubmit()}
            icon={<SendOutlined style={{verticalAlign: "0.1rem"}} />}
            onClick={() => submitNote()}
            loading={submitting}
            ghost
          >
            Submit
          </Button>
        </Col>
      </Row>
    </>
  );
};

export default Mentions;
