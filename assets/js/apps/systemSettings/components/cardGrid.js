import React from "react";
import { Card } from "antd";

const { Grid } = Card;

const gridStyle = {
    width: '25%',
    textAlign: 'center'
}

function cardGrid(index, title, url, description) {
    return (
        <Grid 
            key={index}
            hoverable 
            style={gridStyle}
        >
            <a href={url}>
                <span>{title}</span>
            </a>
            <p>{description}</p>
        </Grid>
    )
}

export default cardGrid;