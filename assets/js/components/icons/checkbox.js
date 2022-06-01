import React from "react";

const CheckboxSvg = ({
  checked,
  hover,
  disabled,
  indeterminate,
}) => {
  if (indeterminate) {
    return (
      <>
        <svg width="16" height="16" viewBox="0 0 16 16" fill="none" xmlns="http://www.w3.org/2000/svg">
          <path d="M0 2C0 0.895431 0.895431 0 2 0H14C15.1046 0 16 0.895431 16 2V14C16 15.1046 15.1046 16 14 16H2C0.895431 16 0 15.1046 0 14V2Z" fill={hover ? "#117140" : "#1DBD6B"} />
          <path d="M10.688 8.489H5.745C5.334 8.489 5 8.156 5 7.745C5 7.334 5.334 7 5.745 7H10.688C11.099 7 11.433 7.334 11.433 7.745C11.433 8.156 11.099 8.489 10.688 8.489Z" fill="white" />
          <path d="M2 1H14V-1H2V1ZM15 2V14H17V2H15ZM14 15H2V17H14V15ZM1 14V2H-1V14H1ZM2 15C1.44772 15 1 14.5523 1 14H-1C-1 15.6569 0.343146 17 2 17V15ZM15 14C15 14.5523 14.5523 15 14 15V17C15.6569 17 17 15.6569 17 14H15ZM14 1C14.5523 1 15 1.44772 15 2H17C17 0.343146 15.6569 -1 14 -1V1ZM2 -1C0.343146 -1 -1 0.343146 -1 2H1C1 1.44772 1.44772 1 2 1V-1Z" fill={hover ? "#117140" : "#1DBD6B"} />
        </svg>
      </>
    );
  }
  if (checked) {
    return (
      <>
        <svg width="16" height="16" viewBox="0 0 16 16" fill="none" xmlns="http://www.w3.org/2000/svg">
          <rect x="0.5" y="0.5" width="15" height="15" rx="1.5" fill={disabled ? "#C2CCCE" : hover ? "#117140" : "#1DBD6B"} />
          <path d="M12 5L6.5 10.5L4 8" stroke="white" strokeLinecap="round" strokeLinejoin="round" />
          <rect x="0.5" y="0.5" width="15" height="15" rx="1.5" stroke={disabled ? "#C2CCCE" : hover ? "#117140" : "#1DBD6B"} />
        </svg>
      </>
    );
  }

  return (
    <>
      <svg width="20" height="20" viewBox="0 0 20 20" fill="none" xmlns="http://www.w3.org/2000/svg">
        <g filter="url(#filter0_d)">
          <rect x="2" y="1" width="16" height="16" rx="2" fill="white" />
          <rect x="2.5" y="1.5" width="15" height="15" rx="1.5" stroke={disabled ? "#EEEEEE" : hover ? "#B1B1B1" : "#E3E3E3"} />
        </g>
        <defs>
          <filter id="filter0_d" x="0" y="0" width="20" height="20" filterUnits="userSpaceOnUse" colorInterpolationFilters="sRGB">
            <feFlood floodOpacity="0" result="BackgroundImageFix" />
            <feColorMatrix in="SourceAlpha" type="matrix" values="0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 127 0" />
            <feOffset dy="1" />
            <feGaussianBlur stdDeviation="1" />
            <feColorMatrix type="matrix" values="0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0.05 0" />
            <feBlend mode="normal" in2="BackgroundImageFix" result="effect1_dropShadow" />
            <feBlend mode="normal" in="SourceGraphic" in2="effect1_dropShadow" result="shape" />
          </filter>
        </defs>
      </svg>
    </>
  );
};

export default CheckboxSvg;
