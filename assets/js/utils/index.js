const capitalize = (string) => {
  if (!string) return '';
  return `${string[0].toUpperCase()}${string.substr(1, string.length)}`
};

const capsLock = (string) => {
  if (!string) return '';
  return string.toUpperCase();
}

const titleize = (string) => {
  return string.replace(/_/g, ' ').split(' ').map(s => capitalize(s)).join(' ');
};

const toCurr = (num, symbol = '$') => {
  if (!num && num !== 0) return '';
  return symbol + parseFloat(num).toFixed(2).replace(/\B(?=(\d{3})+(?!\d))/g, ",");
};

const toAccounting = (num) => {
  if (!num && num !== 0) return '-';
  const parsed = parseFloat(num).toFixed(2).replace(/\B(?=(\d{3})+(?!\d))/g, ",");
  if (num < 0) {
    return `(${parsed.substr(1)})`
  } else {
    return parsed;
  }
};

const percentageCalculator = (high, low) => {
  if (high === 0 || low === 0) return 0.00;
  return (low / high) * 100
};

const toPercent = (num) => {
  if (num === "N/A") return "N/A";
  return num.toFixed(2)
};

const prepad = (number, places = 6) => {
  const initial = `00000${number}`;
  return initial.substring(initial.length - places);
};

const LangConverter = {
  ones: ['', 'one', 'two', 'three', 'four', 'five', 'six', 'seven', 'eight', 'nine'],
  tens: ['', '', 'twenty', 'thirty', 'forty', 'fifty', 'sixty', 'seventy', 'eighty', 'ninety'],
  teens: [...Array(10)].concat(['ten', 'eleven', 'twelve', 'thirteen', 'fourteen', 'fifteen', 'sixteen', 'seventeen', 'eighteen', 'nineteen']),
  toLangConvert(num) {
    const hundreds = Math.floor(num / 100);
    const remainder = num - (hundreds * 100);
    const numTens = Math.floor(remainder / 10);
    const numOnes = remainder - (numTens * 10);
    const numTeens = (numTens * 10) + numOnes;
    const {ones, tens, teens, append} = LangConverter;
    return `${append(ones[hundreds], 'hundred')} ${tens[numTens] || ''} ${teens[numTeens] || ones[numOnes] || ''}`.replace(/\s+/g, ' ');
  },
  append(num, unit) {
    return (num && num !== ' ') ? `${num} ${unit}` : '';
  },
  convertCents(number) {
    const cents = number % 1;
    if (cents === 0) return '';
    const numCents = cents.toFixed(2).replace('0.', '');
    return ` and ${numCents}/100`;
  },
  numToLang(number) {
    const {toLangConvert, append, convertCents} = LangConverter;
    const thousands = Math.floor(number / 1000);
    const hundreds = Math.floor(number - (thousands * 1000));
    return `${append(toLangConvert(thousands), 'thousand')} ${toLangConvert(hundreds)}${convertCents(number)}`.replace(/\s+/g, ' ').replace(/^\s/g, '');
  }
};

const {numToLang} = LangConverter;

const safeRegExp = (string) => {
  try {
    return new RegExp(string, 'i')
  } catch (e) {
    return new RegExp(string.replace(/[\-\[\]\/\{\}\(\)\*\+\?\.\\\^\$\|]/g, "\\$&"), 'i');
  }
};

//TO BE USED TO SEE IF THE PASSED IN USER ID IS THE SAME AS THE CURRENT USER
//MUST BE PASSED IN AS A STRING
const isUser = (userID) => {
  return parseInt(window.user.id) === userID || userID === window.user.id;
};

const currentUserId = () => {
  return parseInt(window.user.id) || userID === window.user.id;
}

const b64toBlob = (b64Data, contentType = '', sliceSize = 512) => {
  const byteCharacters = atob(b64Data);

  const byteArrays = [];

  for (let offset = 0; offset < byteCharacters.length; offset += sliceSize) {
    const slice = byteCharacters.slice(offset, offset + sliceSize),
      byteNumbers = new Array(slice.length);
    for (let i = 0; i < slice.length; i++) {
      byteNumbers[i] = slice.charCodeAt(i);
    }
    const byteArray = new Uint8Array(byteNumbers);

    byteArrays.push(byteArray);
  }

  return new Blob(byteArrays, {type: contentType});
};

const sum = (array, field) => array.reduce((total, item) => (field ? item[field] : item) + total, 0);

const toQueryString = (params) => Object.keys(params).reduce((s, k) => s + `${k}=${params[k]}&`, '?').slice(0, -1);

export {
  capitalize,
  titleize,
  toCurr,
  toAccounting,
  toPercent,
  numToLang,
  prepad,
  safeRegExp,
  sum,
  isUser,
  b64toBlob,
  toQueryString,
  percentageCalculator,
  capsLock,
  currentUserId
};
