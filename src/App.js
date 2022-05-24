import React, { Component } from 'react';
import Web3 from 'web3'
import { Container, Row } from 'react-bootstrap';

class App extends Component {


  constructor(props) {
    super(props)
    this.state = {
      account: '',
      productCount: 0,
      products: [],
      loading: true
    }
  }

  async UNSAFE_componentWillMount(){
    await this.loadWeb3()
    await this.loadBlockchainData();
  }

  async loadWeb3(){
    if(window.ethereum){
      window.web3 = new Web3(window.ethereum)
      const account = await window.ethereum.request({ method: 'eth_requestAccounts' });
    }
    else if (window.web3){
      window.web3 = new Web3(window.web3.currentProvider)
    }
    else{
      window.alert('Non-Ethereum browser detected. You should consider trying MetaMask!');
    }
  }

  async loadBlockchainData(){
    const web3 = window.web3
    const accounts = await web3.eth.getAccounts()
    console.log(accounts)
    this.setState({ account: accounts[0] })
  }

  render() {
    return (
      <Container fluid className = "my-auto">
        <Row style={{marginBottom:'10px', marginTop:'10px'}}>
          Hello,{this.state.account}
        </Row>
          <div style={{display: 'flex', justifyContent: 'center', height:'100vh', marginTop:'300px',fontSize:'60px'}}>
            Welcome to Monster Game
          </div>
       
      </Container>

    );
  }
}

export default App;
