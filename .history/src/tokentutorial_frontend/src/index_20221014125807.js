import React from 'react';
import ReactDOM from 'react-dom';
import { createRoot } from 'react-dom/client';

import App from './app';
import {HashRouter} from "react-router-dom";
import "bootstrap/dist/css/bootstrap.css";
import "bootstrap/dist/js/bootstrap";
import "./custom.scss";
import "jquery/dist/jquery";
import "@popperjs/core/dist/cjs/popper";

import {
    RecoilRoot
} from 'recoil';

function RealRoot() {
    return (
      <RecoilRoot>
        <HashRouter>
            <App />
        </HashRouter>
      </RecoilRoot>
    );
  }

const container = document.getElementById('root');
const root = createRoot(container);
root.render(<RealRoot/>);