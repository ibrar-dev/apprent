import React, {useState} from 'react';
import {Button, Tooltip, Badge, Popconfirm} from 'antd';
import ReactDOMServer from "react-dom/server";
import axios from "axios";

const IconButton = ({icon, loading, title, className, disabled, onClick, badge, style}) => {
  return <Badge count={badge} style={styles.badge}>
    <Button type="link" loading={loading} onClick={disabled ? null : onClick} icon={<i className={`fa-lg ${icon}`} />}>
      {" "}{title}
    </Button>
  </Badge>
}

const ConfirmationIconButton = ({icon, loading, title, className, disabled, onClick, badge, confirmTitle, style}) => {
  return <Badge count={badge} style={styles.badge}>
    <Popconfirm title={confirmTitle} onConfirm={disabled ? null : onClick}>
      <Button type="link" icon={<i className={`fa-lg ${icon}`} />}>
        {" "}{title}
      </Button>
    </Popconfirm>
  </Badge>
}

function sendPDFUp(data, fileName, setFetching, setError) {
  const html = ReactDOMServer.renderToString(data);
  setFetching(true);
  const promise = axios.post("/api/data", {html});
  promise.then((r) => {
    const source = `data:application/pdf;base64,${r.data}`;
    const link = document.createElement("a");
    link.href = source;
    link.download = fileName;
    link.click();
  })
  promise.catch((e) => {
    console.warn(e);
    setError(true);
  });
  promise.finally(() => setFetching(false));
}

const PDFExport = ({data, fileName}) => {
  const [fetching, setFetching] = useState(false);
  const [error, setError] = useState(false);
  return (
    <IconButton
      onClick={() => sendPDFUp(data, fileName, setFetching, setError)}
      title={"Print"}
      loading={fetching}
      icon={'fas text-apprent fa-print'} />
  );
};

const styles = {
  badge: {
    backgroundColor: "#325f3e"
  }
}

export {IconButton, ConfirmationIconButton, PDFExport}
