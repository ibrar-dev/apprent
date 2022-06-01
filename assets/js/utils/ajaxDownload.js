import axios from 'axios';

const extractFilename = (response) => {
  return response.headers['content-disposition'].replace('attachment; filename="', '').replace(/"$/, '').replace(/\+/g, ' ');
};

export default (url, filename) => {
  axios({
    url,
    method: 'GET',
    responseType: 'blob'
  }).then((response) => {
    const url = window.URL.createObjectURL(new Blob([response.data]));
    const link = document.createElement('a');
    link.href = url;
    link.setAttribute('download', filename || extractFilename(response));
    document.body.appendChild(link);
    link.click();
  });
}