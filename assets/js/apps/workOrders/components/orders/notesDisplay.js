import React, {useState, useEffect} from "react";
import {Divider, Comment} from "antd";
import {connect} from "react-redux";
import moment from "moment";
import Mentions from "./mentions";
import actions from "../../actions";

const attachmentRender = (type, url) => {
  if (type.includes("image")) return <img className="img-fluid" src={url} alt="" />;
  if (type.includes("pdf")) return <a href={url} target="_blank" rel="noreferrer">View PDF</a>;
  return <span>DOWNLOAD</span>;
};

const uniqAsgns = (asgns) => (
  Array.from(new Set(asgns.map((a) => a.id))).map((id) => asgns.find((a) => a.id === id))
);

const getDateTime = ({type, inserted_at: insertedAt, updated_at: updatedAt}) => (
  type ? insertedAt : updatedAt
);

const parseTime = (t) => (
  new Date(moment(getDateTime(t))).getTime()
);

const sortedStuff = (notes, assignments) => {
  return [...notes, ...assignments].sort((a, b) => (parseTime(a) - parseTime(b)))
};

const displayName = ({tenant, admin, tech, creator}) => {
  // For now we fetch notes and mix with assignments, that still uses .creator
  if (creator) return creator;
  if (admin) return admin.name;
  if (tech) return tech.name;
  if (tenant) return tenant.first_name + " " + tenant.last_name;
  return "";
};

const getText = (item) => {
  if (item.attachment_url?.url) return attachmentRender(item.attachment.content_type, item.attachment_url.url);
  if (item.text) return item.text;
  if (item.tech_comments) return item.tech_comments;
  // We go down this path on images saved with tech comments
  return (
    <img
      className="img-fluid"
      alt=""
      src={`https://s3-us-east-2.amazonaws.com/appcount-maintenance/notes/prod/${item.id}/${item.image}`}
    />
  );
};

const NotesDisplay = ({order, onNewNoteSuccess, admins, maxHeight}) => {
  const [fetchedNotes, setFetchedNotes] = useState([]);

  const {assignments, tenant, id, type, notes_count, notes} = order;
  useEffect(() => {
    // We expect this path when accessed from the index view
    if (notes_count > 0) {
      const onSuccess = (r) => setFetchedNotes(r.data);
      actions.fetchOrderNotes(id, type, onSuccess);
    }
    // We expect this path when accessed from the show page of Maintenance
    if (notes && notes.length) {
      const onSuccess = (r) => setFetchedNotes(r.data);
      actions.fetchOrderNotes(id, "Maintenance", onSuccess);
    }
  }, []);

  const orderAsigns = assignments ? uniqAsgns(assignments.filter((a) => a.tech_comments)) : [];
  const sorted = sortedStuff(fetchedNotes, orderAsigns);
  return (
    <>
      <div style={{maxHeight: maxHeight || 500, overflowY: "auto"}}>
        {sorted.length > 0 && sorted.map((n) => (
          <div key={n.id}>
            <Comment
              key={n.id}
              author={displayName(n)}
              datetime={moment(getDateTime(n)).format("MM/DD/YY hh:mmA")}
              content={getText(n)}
            />
            <Divider />
          </div>
        ))}
      </div>
      <Mentions tenant={tenant} admins={admins} order={order} onNewNoteSuccess={onNewNoteSuccess} />
    </>
  );
};

export default connect(({admins}) => ({admins}))(NotesDisplay);
