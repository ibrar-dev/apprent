export const defaultMentionStyle = {
  backgroundColor: "rgba(50, 83, 239, .15)",
  color: "blue",
};

export const defaultStyle = {
  control: {
    minHeight: 63,
  },
  highlighter: {
    padding: 9,
    border: "1px solid transparent",
  },
  input: {
    padding: 9,
    border: "1px solid silver",
    borderRadius: "3px",
  },

  suggestions: {
    list: {
      borderRadius: "5px",
      backgroundColor: "white",
      border: "1px solid rgba(0,0,0,0.15)",
      overflow: "auto",
      maxHeight: 250,
    },
    item: {
      padding: "5px 15px",
      borderBottom: "1px solid rgba(0,0,0,0.15)",
      "&focused": {
        backgroundColor: "rgba(50, 83, 239, .25)",
      },
    },
  },
};