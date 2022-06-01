const baseColors = [
  '#F7464A',
  '#46BFBD',
  '#b3acff',
  '#FDB45C',
  '#b9bbbf',
  '#000000',
  '#5D54FF',
  '#ab3a9b',
  '#d6ff95',
  '#32AF20'
];

export default (factor, total, alpha = 1.0) => {
  const base = baseColors[factor % baseColors.length];
  const index = factor % 3;
  const rgb = base.replace('#', '').match(/../g);
  let num = parseInt(rgb[index], 16) + (Math.round(Math.random() * 100));
  while (num > 255) num = num - 255;
  rgb[index] = `0${num.toString(16)}`.replace(/.(..)/, '$1');
  return 'rgba(' + rgb.map(color => {
    let num = parseInt(color, 16) + (Math.round(250 / total) * (factor % 5));
    while (num > 255) num = num - 255;
    return num;
  }).join(',') + `, ${alpha})`;
}