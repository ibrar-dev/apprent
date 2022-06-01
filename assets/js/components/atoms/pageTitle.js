import React from "react";
import styled from "styled-components";
import device from "../../components/atoms/utils/device";

const PageTitle = ({title, children, count}) => (
  <div className="flex items-center">
    {children
        && (
        <div className="mr-1.5">
          {children}
        </div>
        )}
    <Title>
      {title}
    </Title>
    {count
        && (
        <CountNumber>
          (
          {count}
          )
        </CountNumber>
        )}
  </div>
);

const Title = styled.div`
  color: #04333B;
  font-weight: 500;
  font-size: 14px;
  line-height: 17px;

  @media ${device.tablet} {
    font-size: 32px;
    line-height: 23px;
  }
`;

const CountNumber = styled.div`
  color: #9EACB0;
  font-weight: 400;
  font-size: 14px;
  margin-left: 2px;
  line-height: 17px;

  @media ${device.tablet} {
    font-size: 24px;
    margin-left: 10px;
    line-height: 29px;
  }
`;

export default PageTitle;