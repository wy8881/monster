import React, {Component} from 'react';
import MonsterMarket from '../abis/MonsterMarket.json'
import MonsterToken from '../abis/MonsterToken.json';
import Web3 from 'web3';
import { Container, Row,Button, Col, Modal, Form } from 'react-bootstrap';

const dragonPicture = new URL("../public/images/race/dragon.png", import.meta.url)
const ghostPicture = new URL("../public/images/race/ghost.png", import.meta.url)
const gargoylePicture = new URL("../public/images/race/gargoyle.png", import.meta.url)

class Market extends Component{
  constructor(props){
      super(props)
      this.state = {
          account:'',
          productCount:0,
          products:[],
          loading:true,
          balance:0,
          show:false,
          amount:0
      }
  }

  async UNSAFE_componentWillMount(){
      await this.loadWeb3()
      await this.loadBlockchainData();
    }
    
    async loadWeb3(){
      if(window.ethereum){
        window.web3 = new Web3(window.ethereum)
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
      const tokenNetwork = MonsterToken.networks[networkId]
      if(tokenNetwork){
        const monstertoken = new web3.eth.Contract(MonsterToken.abi,tokenNetwork.address)
        this.setState({monstertoken})
        const deposit = await monstertoken.methods.depositOf(this.state.account).call({from: this.state.account})
        const ownedMonsters = await monstertoken.methods.getOwnedMonster().call({from:this.state.account})
        this.setState({balance:window.web3.utils.fromWei(deposit,'ether')})
      }else{
        window.alert('MonsterToken contract not deployed to be deteced')
      }
      if(marketNetwork){
        const monstermarket = new web3.eth.Contract(MonsterMarket.abi,marketNetwork.address)
        this.setState({monstermarket})
        const products = await monstermarket.methods.getAllProducts().call({from:this.state.account})
        var productArray = new Array(products.length)
        for(var i = 1; i <= products.length; i++){
          var image = this.setImg(products[i-1][6])
          var price = window.web3.utils.fromWei(products[i-1][2],'ether');
          var product = {
                        Id:products[i-1][0]
                        ,owner:products[i-1][3]
                        ,price:price
                        ,level:products[i-1][4]
                        ,HP:products[i-1][5][0]
                        ,strength:products[i-1][5][1]
                        ,defensive:products[i-1][5][2]
                        ,speed:products[i-1][5][3]
                        ,img:image}
          productArray[i-1] = product
        }
        productArray.sort((a,b) => a.Id - b.Id)
        this.setState({products:productArray})
        this.setState({productCount:productArray.length})
        this.setState({loading:false})
      }else{
        window.alert('MonsterMarket contract not deployed to be deteced')
      }
      this.setState({loading:false})
    }

    setImg = (race) =>{
      switch(race){
        case '0': return dragonPicture;
        case '1': return ghostPicture;
        case '2': return gargoylePicture;
      }
    }

    
  async sendEth(amount){
    
    var eth_amount = window.web3.utils.toWei(amount,'ether');
    await window.web3.eth.sendTransaction({to: this.state.monstertoken._address,from:this.state.account, value: eth_amount},(err,transactionHash) =>{
      if(err){
        window.alert("transaction declined")
      }else window.location.reload()
    })
  }

  async buy(Id) {
    try{
      await this.state.monstermarket.methods.buyMonsters(Id).send({from:this.state.account})
      window.alert("Buy successfully!")
      window.location.reload()
    }catch(err){
      if(err){
        if(this.getRPCErrorMessage(err) == "revert does not have enough money to buy")
        window.alert( "Sorry, you dont have enough money for this. Please deposit money")
        window.location.reload()
      }
    }
  }

  async withdraw(){
    try{
      await this.state.monstertoken.methods.withdraw().send({from:this.state.account})
      window.alert("Withdraw successfully! Refresh to check")
      window.location.reload()
    }catch(err){
      if(err){
        window.alert("unexpected mistake")
      }
    }
  }

    getRPCErrorMessage(err){
      var middle =  err.stack.substring(178, err.message.length - 2)
      var index = middle.indexOf('\\')
      return middle.substring(0,index)
    }

    handleBuy = (event) =>{
      this.buy(event.target.value)
    }

    handleShow = () => {
      this.setState({show:true})
    }
  
    handleClose= () =>{
      this.setState({show:false})
    }

    handleETHChange = (event) =>{
      this.setState({amount:event.target.value})
    }

    handleSend = () =>{
      this.sendEth(this.state.amount)
      this.handleClose()
      
    }

    handleWithdraw = () =>{
      this.withdraw()
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
                        <div style={{marginTop:"20px",marginBottom:'10px'}} className = "d-flex flex-wrap">
                          {this.state.products.map((content) =>(
                            <a key = {content.Id} className="list-group-item list-group-item-action flex-column align-self-center">
                                <div className="d-flex w-200 justify-content-between">
                                  <img src = {content.img} width="100" height="100"/>
                                  <small>level {content.level}</small>
                                </div>
                                  <div className = "d-flex justify-content-between">
                                    <p>id: {content.Id}</p>
                                  </div>
                                  <p>price: {content.price} ETH</p>
                                  <div className = "d-flex justify-content-between">
                                  <p>HP: {content.HP}</p>
                                    <p>strength: {content.strength}</p>
                                    <p>defensive: {content.defensive}</p>
                                    <p>speed: {content.speed}</p>
                                  </div>
                                  <div>
                                    {
                                      content.owner == this.state.account
                                      ?
                                      <div className = "d-flex justify-content-center">
                                        <Button variant='outline-primary' disabled>This is your monster</Button>
                                      </div>
                                      
                                      :
                                      <div className = "d-flex justify-content-center"> 
                                        <Button variant='outline-primary' value = {content.Id} onClick = {this.handleBuy}>Buy</Button>
                                      </div>
                                    }
                                  </div>
                              </a>
                          ))}
                          <p>Now there are {this.state.productCount} products</p>
                        </div>
                      </Row>
                      <Row style={{marginBottom:'10px', marginTop:'10px'}} md={4}> 
                        <Col> 
                          balance: {this.state.balance} ETH
                        </Col>
                        <Col md = {1}> 
                          <Button variant="outline-primary" onClick={this.handleShow}>
                              Send Eth
                          </Button>

                        </Col>
                        <Col >
                          <Button variant="outline-primary" onClick={this.handleWithdraw}>
                              Withdraw
                          </Button>
                        </Col>
                      </Row>
                      <Modal show={this.state.show} onHide={this.handleClose}>
                        <Modal.Body>
                          <Form>
                            <Form.Group className="mb-3" >
                              <Form.Label>Eth amount</Form.Label>
                              <Form.Control
                                  type="text"
                                  autoFocus
                                  value={this.state.value}
                                  onChange = {this.handleETHChange}/>
                            </Form.Group>
                          </Form>
                        </Modal.Body>
                        <Modal.Footer>
                          <Button variant="secondary" onClick={this.handleClose}>
                              Close
                          </Button>
                          <Button variant="primary" onClick = {this.handleSend}>
                              Send
                          </Button>
                        </Modal.Footer>
                      </Modal>                  
                  </Container>
              }
            </div>
        )
    }
}

export default Market;