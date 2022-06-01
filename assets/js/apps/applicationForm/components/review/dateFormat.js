export default (date) => {
  if (date.format) return date.format("MMM D YYYY");
  return date;
};