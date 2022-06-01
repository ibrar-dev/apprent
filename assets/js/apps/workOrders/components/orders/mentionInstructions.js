import React from "react";

const MentionInstructions = (hasValidResident) => (
  hasValidResident
    ? (
      <p className="text-lef mt-2">
        Use
        {" "}
        <b>@</b>
        {" "}
        to notify a user or
        {" "}
        <b>@resident</b>
        {" "}
        to notify the resident.
      </p>
    )
    : (
      <p className="text-left mt-2">
        Use
        {" "}
        <b>@</b>
        {" "}
        to notify a user. The resident cannot be notified this way
        as they do not have an email address.
      </p>
    )
);

export default MentionInstructions;
