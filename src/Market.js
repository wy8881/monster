import React, {Component} from 'react';
import MonsterMarket from '../abis/MonsterMarket.json'
import Web3 from 'web3';
import { Container, Row } from 'react-bootstrap';

class Market extends Component{
    constructor(props){
        super(props)
        this.state = {
            account:'',
            productCount:0,
            products:[],
            loading:true
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
        this.setState({ account: accounts[0] })
        const networkId = await web3.eth.net.getId()
        const marketNetwork = MonsterMarket.networks[networkId]
        if(marketNetwork){
          const monstermarket = new web3.eth.Contract(MonsterMarket.abi,marketNetwork.address)
          this.setState({monstermarket})
        }else{
          window.alert('MonsterMarket contract not deployed to be deteced')
        }
        this.setState({loading:false})
      }
    
    render(){
        return(
            <div>
                {
                    this.state.loading
                    ? <p>loading...</p>
                    :
                    <Container fluid>
                        <Row style={{marginBottom:'10px', marginTop:'10px'}}>
                            Hello,{this.state.account}
                        </Row>
                        <Row style={{marginBottom:'10px', marginTop:'10px'}} md={4}>
                            
                        </Row>
                    </Container>
                }
                <h1>
                    back to home
                </h1>
            </div>
        )
    }
}

export default Market;