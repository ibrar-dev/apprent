import React from "react";

const MagnifyingGlassSvg = ({color}) => (
  <svg width="17" height="16" viewBox="0 0 17 16" fill="none" xmlns="http://www.w3.org/2000/svg">
    <path d="M7.33702 12.6667C10.284 12.6667 12.6731 10.2789 12.6731 7.33333C12.6731 4.38781 10.284 2 7.33702 2C4.39 2 2.00098 4.38781 2.00098 7.33333C2.00098 10.2789 4.39 12.6667 7.33702 12.6667Z" stroke={color || "#1DBD6B"} strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round" />
    <path d="M14.0072 14.0001L11.1057 11.1001" stroke={color || "#1DBD6B"} strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round" />
  </svg>
);

export default MagnifyingGlassSvg;
