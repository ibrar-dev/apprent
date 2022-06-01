const regex = /.*admin_token=/;
export default document.cookie.split(';').filter(c => regex.test(c))[0].replace(regex, '');
