import { Outlet, Link } from "react-router-dom";
import "./style.css"
import React, {Component} from 'react';
import Web3 from 'web3';

class Navabar extends Component{

  constructor(props){
    super(props)
  }

  render(){
    return (
      <>
      <nav>
        <ul className="Navavar list" style={{listStyle:"none",float:"right"}}>
          <li>
            <Link to="/">Home</Link>
          </li>
          <li>
            <Link to ="/mymonster">My Monster</Link>
          </li>
          <li>
            <Link to = "/market">Market</Link>
          </li>
          <li>
            <Link to = "/battle">Battle</Link>
          </li>
        </ul>
        
      </nav>

      <Outlet />
      </>
        )
  }
  
}
export default Navabar;
