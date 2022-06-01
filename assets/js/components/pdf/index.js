import React, {useState} from "react";
import ReactDOMServer from "react-dom/server";
import axios from "axios";
import {Button} from "antd";

const dataToExport = (array, columns) => (
  <table className="table">
    <thead>
      <tr className="text-left bg-success text-white">
        {columns.map((c) => <th key={c}>{c}</th>)}
      </tr>
    </thead>
    <tbody>
      {array.map((o, i) => (
        <tr key={`row${i}`}>
          {o.map((attr, ind) => <td key={`pdf${ind}`}>{attr}</td>)}
        </tr>
      ))}
    </tbody>
  </table>
);

const sendPDFUp = (rows, columns, fileName, setFetching, setError) => {
  const html = ReactDOMServer.renderToString(dataToExport(rows, columns));
  const promise = axios.post("/api/data", {html});
  setFetching(true);
  promise.then((r) => {
    const source = `data:application/pdf;base64,${r.data}`;
    const link = document.createElement("a");
    link.href = source;
    link.download = fileName;
    link.click();
  });
  promise.catch((e) => {
    console.warn(e);
    setError(true);
  });
  promise.finally(() => setFetching(false));
};

const pdfExport = ({rows, columns, fileName}) => {
  const [fetching, setFetching] = useState(false);
  const [error, setError] = useState(false);
  return (
    <Button
      loading={fetching}
      onClick={() => sendPDFUp(rows, columns, fileName, setFetching, setError)}
      shape="circle"
      icon={<i className={`far fa-${error ? "text-danger exclamation-triangle" : "file-pdf"}`} />}
    />
  );
};

export default pdfExport;
