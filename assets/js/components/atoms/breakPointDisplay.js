import React from 'react';
import styled from 'styled-components';

const BreakpointDisplay = ({ breakpoint, children, under }) => {
  let shouldShow = window.innerWidth > breakpoint;

  if (under) shouldShow = !shouldShow;

  return <Wrapper shouldShow={shouldShow}>{children}</Wrapper>
};

export const Wrapper = styled.div`
  display: ${p => p.shouldShow ? "block" : "none"};
`;

export default BreakpointDisplay;