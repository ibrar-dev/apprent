const getCookie = (value) => {
  const regex = new RegExp(`.*${value}=`);
  const cookie = document.cookie.split(';').filter(c => regex.test(c))[0];
  if (!cookie) return null;
  return cookie.replace(regex, '');
};

const setCookie = (key, value) => {
  if (location.protocol === 'https:') {
    document.cookie = `${key}=${value};secure`;
  } else {
    document.cookie = `${key}=${value}`;
  }
};

export {setCookie, getCookie}