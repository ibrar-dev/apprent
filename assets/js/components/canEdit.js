const canEdit = (roles) => {
  return window.roles.some(r => roles.includes(r));
};

export default canEdit;