module.exports = {
  env: {
    browser: true,
    es2020: true,
  },
  extends: [
    "plugin:react/recommended",
    "airbnb",
  ],
  parserOptions: {
    ecmaFeatures: {
      jsx: true,
    },
    ecmaVersion: 11,
    sourceType: "module",
  },
  plugins: [
    "react",
  ],
  rules: {
    "react/prop-types": 0,
    "react/jsx-filename-extension": [1, {extensions: [".js", ".jsx"]}],
    "object-curly-spacing": ["error", "never"],
    quotes: ["error", "double", {avoidEscape: true}],
    "class-methods-use-this": 0,
  },
};
