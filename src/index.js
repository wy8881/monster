import React from 'react';
import ReactDOM from 'react-dom/client';
import './index.css';
import Navabar from './Navabar';
import reportWebVitals from './reportWebVitals';
import { BrowserRouter , Routes, Route} from 'react-router-dom'
import App from './App';
import Market from './Market';
import Battle from './Battle';
import MyMonster from './MyMonster';


export default function Index() {
    return (
      <BrowserRouter>
        <Routes>
          <Route path="/" element={<Navabar/>}>
            <Route index element={<App />} />
            <Route path = "mymonster" element = {<MyMonster/>}/>
            <Route path="market" element={<Market />} />
            <Route path = "battle" element = {<Battle/>}/>
          </Route>
        </Routes>
      </BrowserRouter>
    );
  }
  
  const root = ReactDOM.createRoot(document.getElementById('root'));
  root.render(<Index/>);
  
  
// If you want to start measuring performance in your app, pass a function
// to log results (for example: reportWebVitals(console.log))
// or send to an analytics endpoint. Learn more: https://bit.ly/CRA-vitals
reportWebVitals();
