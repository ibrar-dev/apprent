import React, {useState} from 'react';
import {Button} from 'antd';
import axios from 'axios';

function sendPDFUp(html, fileName, setFetching, setError) {
  const promise = axios.post("/api/data", {html});
  setFetching(true);
  promise.then(r => {
    const source = `data:application/pdf;base64,${r.data}`;
    const link = document.createElement("a");
    link.href = source;
    link.download = fileName;
    link.click();
  });
  promise.catch(e => {
    setError(true)
  });
  promise.finally(() => setFetching(false))
}

function iconButton(html, fileName) {
  const [fetching, setFetching] = useState(false);
  const [error, setError] = useState(false);
  return <div className={"fa-lg mr-3"}>
    <i
      onClick={() => sendPDFUp(html, fileName, setFetching, setError)}
      className={`${fetching ? 'fas fa-spinner fa-spin' : 'far fa-file-pdf'} cursor-pointer`}
    />
  </div>
}

export default iconButton;
