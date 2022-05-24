import React, {Component} from 'react';
import Web3 from 'web3';
import MonsterToken from '../abis/MonsterToken.json';
import MonsterMarket from '../abis/MonsterMarket.json'
import 'bootstrap/dist/css/bootstrap.css';
import {Container,Row, Col, Button, Modal , Form, ListGroup} from 'react-bootstrap';
const dragonPicture = new URL("../public/images/race/dragon.png", import.meta.url)
const ghostPicture = new URL("../public/images/race/ghost.png", import.meta.url)
const gargoylePicture = new URL("../public/images/race/gargoyle.png", import.meta.url)

class MyMonster extends Component{    
  constructor(props){
    super(props)
    this.state = {
      account:'',
      balance:0,
      tokenAccount:0,
      monsters:[],
      loading:true,
      show:false,
      showForSell:false,
      amount:0,
      productId:0,
      price:0,
      ownedMonsterLoading:true
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
    const tokenNetwork = MonsterToken.networks[networkId]
    const marketNetwork = MonsterMarket.networks[networkId]
    if(tokenNetwork){
      const monstertoken = new web3.eth.Contract(MonsterToken.abi,tokenNetwork.address)
      this.setState({monstertoken})
      const deposit = await monstertoken.methods.depositOf(this.state.account).call({from: this.state.account})
      const ownedMonsters = await monstertoken.methods.getOwnedMonster().call({from:this.state.account})
      // this.setState({tokenAccount:ownedMonsters.length})
      this.setState({balance:window.web3.utils.fromWei(deposit,'ether')})
      var monsters = new Array(ownedMonsters.length)
      for(var i=1; i <= ownedMonsters.length; i++ ){
        var image = this.setImg(ownedMonsters[i-1][7])
        var monster = {
                      Id:ownedMonsters[i-1][0]
                      ,mumId:ownedMonsters[i-1][1]
                      ,dadId:ownedMonsters[i-1][2]
                      ,HP:ownedMonsters[i-1][3][0]
                      ,strength:ownedMonsters[i-1][3][1]
                      ,defensive:ownedMonsters[i-1][3][2]
                      ,speed:ownedMonsters[i-1][3][3]
                      ,level:ownedMonsters[i-1][5]
                      ,exp:ownedMonsters[i-1][6]
                      ,img:image
                      ,islock:ownedMonsters[i-1][8]}
          monsters[i-1] = monster
      }
      monsters.sort((a,b) => a.Id - b.Id)
      this.setState({monsters:monsters})
      this.setState({tokenAccount:monsters.length})
      this.setState({ownedMonsterLoading:false})
    }else{
      window.alert('MonsterToken contract not deployed to be deteced')
    }
    if(marketNetwork){
      const monstermarket = new web3.eth.Contract(MonsterMarket.abi,marketNetwork.address)
      console.log(monstermarket)
      this.setState({monstermarket})
    }else{
      window.alert('MonsterMarket contract not deployed to be deteced')
    }
    this.setState({loading:false})
  }

  async getInitial(race){
    try{
      await this.state.monstertoken.methods.getInitialMonster(race).send({from:this.state.account})
      window.alert('You have get a new monster! Refresh to check')
      window.location.reload()
      
    } catch(err) {
      if (err) {
        if(this.getRPCErrorMessage(err) === "revert should have enough money"){
          window.alert( "Sorry, you dont have enough money for this. Please deposit money")
        }else window.alert("unexpected mistake")
      }   
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

  setImg = (race) =>{
    switch(race){
      case '0': return dragonPicture;
      case '1': return ghostPicture;
      case '2': return gargoylePicture;
    }
  }

  async deleteMonster(id){
    try{
      await this.state.monstertoken.methods.deleteMonster(id).send({from:this.state.account})
      window.alert('You have delete this monster! Refresh to check')
      window.location.reload()
    }catch(err) {
      if (err) {
        window.alert(this.getRPCErrorMessage(err))
      }
    }
  }

  async setProduct(id, price){
    try{
      await this.state.monstermarket.methods.setProduct(id, price).send({from:this.state.account})
      window.alert('This monster has been set as product successfully! Refresh to check')
      window.location.reload()
    }catch(err){
      if(err){
        window.alert(this.getRPCErrorMessage(err))
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
        console.log(err)
      }
    }
  }

  handleShow = () => {
    this.setState({show:true})
  }

  handleClose= () =>{
    this.setState({show:false})
  }

  handleShowForSell =() =>{
    this.setState({showForSell:true})
  }

  handleCloseForSell = () =>{
    this.setState({showForSell:false})
  }

  handleETHChange = (event) =>{
    this.setState({amount:event.target.value})
  }

  handlePriceChange = (event) =>{
    this.setState({price:event.target.value})
  }


  handleSend = () =>{
    this.handleClose()
    this.sendEth(this.state.amount)
  }

  handleCreate = (event) =>{
    this.getInitial(event.target.value)
  }

  handleChoosedProduct = (event) =>{
    this.setState({productId:event.target.value})
    this.handleShowForSell()
  }

  handleSetProduct = () =>{
    this.setProduct(this.state.productId, this.state.price)
  }

  handleWithdraw = () =>{
    this.withdraw()
  }

  handleDelete= (event) =>{
    var result = window.confirm("You can not revert the delet operation!")
    if(result){
      this.deleteMonster(event.target.value)
    }
    
  }

  getRPCErrorMessage(err){
    var middle =  err.stack.substring(178, err.message.length - 2)
    var index = middle.indexOf('\\')
    return middle.substring(0,index)
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
              {
                this.state.ownedMonsterLoading
                ?<p>Loading the list of your owned monsters...</p>
                : 
                <div style={{marginTop:"20px",marginBottom:'10px'}} className = "d-flex flex-wrap">
                {this.state.monsters.map((content) =>(
                  <a key = {content.Id} className="list-group-item list-group-item-action flex-column align-self-center">
                      <div className="d-flex w-200 justify-content-between">
                        <img src = {content.img} width="100" height="100"/>
                        <small>level {content.level}</small>
                      </div>
                        <div className = "d-flex justify-content-between">
                          <p>id: {content.Id}</p>
                          <p>mum id: {content.mumId}</p>
                          <p>dad id: {content.dadId}</p>
                          
                        </div>
                        <div className = "d-flex justify-content-between">
                        <p>HP: {content.HP}</p>
                          <p>strength: {content.strength}</p>
                          <p>defensive: {content.defensive}</p>
                          <p>speed: {content.speed}</p>
                        </div>
                        {
                          content.islock
                          ?<div className = "d-flex justify-content-center">
                            <Button variant='outline-primary' value = {content.Id}>Get back from market</Button>
                          </div>
                          :
                        <div className = "d-flex justify-content-between">
                            <Button variant='outline-primary' value = {content.Id} onClick = {this.handleChoosedProduct}>Sell</Button>
                            <Button variant='outline-primary' value = {content.Id}>Battle with</Button>
                            <Button variant='outline-primary' value = {content.Id} onClick={this.handleDelete}>Delete</Button>
                            
                        </div>
                      }
                    </a>
                ))}
                  <p>you owned {this.state.tokenAccount} monster</p>
                </div>
              }
            </Row>
            
            <Row style={{marginBottom:'10px', marginTop:'10px'}} md={4}>
              <Col > 
                Want to get a new one? (this cost 2 eth)
              </Col>
              <Col md = {1}>
                <Button variant="outline-primary" value = "dragon" onClick={this.handleCreate}>Dragon</Button>
              </Col>
              <Col md = {1}>
                <Button variant="outline-primary" value = "ghost" onClick={this.handleCreate}>Ghost</Button>
              </Col>
              <Col md = {1}>  
                <Button variant="outline-primary" value = "gargoyle" onClick={this.handleCreate}>Gargoyle</Button>
              </Col>
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

            <Modal show={this.state.showForSell} onHide={this.handleCloseForSell}>
              <Modal.Body>
                <Form>
                  <Form.Group className="mb-3" >
                    <Form.Label>Price</Form.Label>
                    <Form.Control
                        type="text"
                        autoFocus
                        value={this.state.value}
                        onChange = {this.handlePriceChange}/>
                  </Form.Group>
                </Form>
              </Modal.Body>
              <Modal.Footer>
                <Button variant="secondary" onClick={this.handleCloseForSell}>
                    Close
                </Button>
                <Button variant="primary" onClick = {this.handleSetProduct}>
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

export default MyMonster;