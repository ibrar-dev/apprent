import {b64toBlob} from "./index";

export default (data) => {
  const newIframe = document.createElement("iframe");
  newIframe.style.height = '0';
  newIframe.style.width = '0';
  newIframe.style.border = 'none';
  const contentType = "application/pdf",
    blob = b64toBlob(data, contentType);
  newIframe.src = URL.createObjectURL(blob);
  newIframe.onload = () => {
    newIframe.focus();
    newIframe.contentWindow.print();
  };
  document.body.appendChild(newIframe);
};