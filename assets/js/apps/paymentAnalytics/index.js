import React from "react";
import PaymentAnalyticsApp from "./components";
import {BrowserRouter} from 'react-router-dom'
import ReactDom from "react-dom";

const container = document.getElementById("payment-analytics-app");

if (container) {
    ReactDom.render(
        <BrowserRouter>
            <PaymentAnalyticsApp />
        </BrowserRouter>,
        container
    )
}