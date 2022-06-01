import styled from "styled-components";
import device from "../../../../../components/atoms/utils/device";

export const CommentsCount = styled.div`
  font-size: 12px;
  color: white;
  font-weight: 500;
  background-color: #1DBD6B;
  border-radius: 30px;
  height: 17px;
  padding-left: 8px;
  padding-right: 8px;

  display: flex;
  align-items: center;
  justify-content: center;
`;

export const ImageWrapper = styled.img`
  width: 16px;
  height: 16px;
  border-radius: 50%;
  object-fit: cover;
  border: 1px solid #1DBD6B;
`;

export const Name = styled.div`
  font-size: 12px;
  font-weight: 400;
  color: #04333B;

  @media ${device.tablet} {
    font-size: 14px;
  }
`;

export const Title = styled.div`
  font-size: 12px;
  font-weight: 400;
  color: #9EACB0;
`;

export const Wrapper = styled.div`
  border: 1px solid #E3E3E3;
  border-radius: 12px;
  box-shadow: 0px 1px 2px rgba(0, 0, 0, 0.08);
  padding: 16px;
  margin-bottom: 10px;
`;
