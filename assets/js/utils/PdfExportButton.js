import React, {useState} from 'react';
import ReactDOMServer from 'react-dom/server'
import axios from 'axios';
import {Button} from 'antd';
import {FilePdfOutlined, WarningOutlined} from "@ant-design/icons"

function makePDF(body, setFetching, setError, fileName){
  const html = ReactDOMServer.renderToString(body)
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
    console.warn(e);
    setError(true)
  });
  promise.finally(() => setFetching(false))
}

function PdfExportButton({body, fileName}) {
  const [fetching, setFetching] = useState(false);
  const [error, setError] = useState(false);

  let icon

  if (error) {
    icon = <WarningOutlined style={{verticalAlign: "0.1rem"}} />
  } else {
    icon = <FilePdfOutlined style={{verticalAlign: "0.1rem"}} />
  }

  return (
    <Button
      loading={fetching}
      onClick={() => makePDF(body, setFetching, setError, fileName)}
      size="large"
      shape="round"
      icon={icon}
      disabled={error}
    >
      Export to PDF
    </Button>
  )
}

export default PdfExportButton;
