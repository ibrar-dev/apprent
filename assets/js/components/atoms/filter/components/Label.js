import styled from "styled-components";

const Label = styled.div`
  white-space: nowrap;
  font-size: 12px;
  font-weight: ${p => p.bold ? '600' : '400'};
`;

export default Label;