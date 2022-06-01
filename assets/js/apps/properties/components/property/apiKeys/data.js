const processors = {
  Authorize: ['API Key', 'Transaction Key', 'Public Key'],
  Payscape: ['Cert', 'Term ID', 'Account Num'],
  BlueMoon: ['Serial', 'User', 'Password', 'Property ID'],
  TenantSafe: ['UserId', 'Password', 'Product Type'],
  Yardi: ['Username', 'Password', 'Platform', 'Server Name', 'DB', 'URL', 'Entity', 'Interface', 'Payment Account Number'],
  '': []
};

const integrationOptions = {
  cc: ['Authorize', 'Payscape'],
  ba: ['Authorize', 'Payscape'],
  lease: ['BlueMoon'],
  screening: ['TenantSafe'],
  management: ['Yardi']
};

const linkFor = (name, login, keys) => {
  const key = {
    Payscape: `https://epay.propay.com/login/?username=${login}`,
    Authorize: 'https://account.authorize.net/',
    BlueMoon: 'https://www.bluemoonforms.com/?p=login',
    Yardi: (keys[5] || '').replace('webservices/', 'pages/LoginAdvanced.aspx'),
    TenantSafe: 'https://tenantsafe.instascreen.net/sso/login.taz'
  };

  return key[name] || '';
};

export {processors, integrationOptions, linkFor}