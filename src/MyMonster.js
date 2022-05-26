import React, {Component} from 'react';
import Web3 from 'web3';
import MonsterToken from '../abis/MonsterToken.json';
import MonsterMarket from '../abis/MonsterMarket.json'
import 'bootstrap/dist/css/bootstrap.css';
import {Container,Row, Col, Button, Modal , Form, ListGroup} from 'react-bootstrap';
const dragonPicture = new URL("../public/images/race/dragon.png", import.meta.url)
const ghostPicture = new URL("../public/images/race/ghost.png", import.meta.url)
const gargoylePicture = new URL("../public/images/race/gargoyle.png", import.meta.url)
const defaultPicture = new URL("../public/images/race/evil-bat.png", import.meta.url)

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
      ownedMonsterLoading:true,
      componentLoading:true,
      showForComponent:false,
      showForBattleChoice:false,
      player1Id:0,
      showForComponent:false,
      showForDefault:false,
      component:[],
      defaultMonster:[{Id:1,level:1,HP:10,strength:4,defensive:4,speed:4,img:defaultPicture},{Id:2,level:5,HP:16,strength:6,defensive:6,speed:6,img:defaultPicture},{Id:2,level:10,HP:24,strength:14,defensive:14,speed:14,img:defaultPicture}],
      breedings:[],
      dadId:0,
      mumId:0
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
    const tokenNetwork = MonsterToken.networks[networkId]
    const marketNetwork = MonsterMarket.networks[networkId]
    if(tokenNetwork){
      const monstertoken = new web3.eth.Contract(MonsterToken.abi,tokenNetwork.address)
      this.setState({monstertoken})
      const deposit = await monstertoken.methods.depositOf(this.state.account).call({from: this.state.account})
      const ownedMonsters = await monstertoken.methods.getOwnedMonster().call({from:this.state.account})
      this.setState({balance:window.web3.utils.fromWei(deposit,'ether')})
      var monsters = new Array(ownedMonsters.length)
      var breedings = []
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
                      ,exp:ownedMonsters[i-1][5]*10 -ownedMonsters[i-1][6]
                      ,img:image
                      ,islock:ownedMonsters[i-1][8]}
        if(!ownedMonsters[i-1][8]){
          var race = this.setRace(ownedMonsters[i-1][7])
          var breeding = {
                      Id:ownedMonsters[i-1][0]
                      ,HP:ownedMonsters[i-1][4][0]
                      ,strength:ownedMonsters[i-1][4][1]
                      ,defensive:ownedMonsters[i-1][4][2]
                      ,speed:ownedMonsters[i-1][4][3]
                      ,race:race}
          breedings.push(breeding)
        }
        
          monsters[i-1] = monster
      }
      monsters.sort((a,b) => a.Id - b.Id)
      breedings.sort((a,b) => a.race.length - b.race.length)
      this.setState({breedings:breedings})
      this.setState({monsters:monsters})
      this.setState({tokenAccount:monsters.length})
      this.setState({ownedMonsterLoading:false})
    }else{
      window.alert('MonsterToken contract not deployed to be deteced')
    }
    if(marketNetwork){
      const monstermarket = new web3.eth.Contract(MonsterMarket.abi,marketNetwork.address)
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

  setRace = (race) =>{
    switch(race){
      case '0': return 'Dragon';
      case '1': return 'Ghost';
      case '2': return 'Gargoyle';
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
      var eth_price = window.web3.utils.toWei(price,'ether');
      await this.state.monstermarket.methods.setProduct(id, eth_price).send({from:this.state.account})
      window.alert('This monster has been set as product successfully! Refresh to check')
      window.location.reload()
    }catch(err){
      if(err){
        window.alert(this.getRPCErrorMessage(err))
      }
    }
  }

  async deleteProduct(id){
    try{
      await this.state.monstermarket.methods.deleteProduct(id).send({from:this.state.account})
      window.alert('Now this product is not on sale')
      window.location.reload()
    }catch(err){
      if(err){
        window.alert("unexpected mistake")
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

  async getComponent(){
    try{
      var components = await this.state.monstertoken.methods.pickCompetitionRandomly().call({from:this.state.account})
      var componentArray = new Array(components.length)
      for(var i=1; i <= components.length; i++ ){
        var image = this.setImg(components[i-1][2])
        var component = {
                      Id:components[i-1][0]
                      ,level:components[i-1][1]
                      ,HP:components[i-1][3][0]
                      ,strength:components[i-1][3][1]
                      ,defensive:components[i-1][3][2]
                      ,speed:components[i-1][3][3]
                      ,img: image
                    }
          componentArray[i-1] = component
      }
      componentArray.sort((a,b) => a.Id - b.Id)
      this.setState({component:componentArray})
      this.setState({componentLoading:false})
    }catch(err){
      if(err){
        window.alert('Unexpected mistake')
        this.setState({showForComponent:false})
      }
    }
  }

  async battleWithPlayer(player1Id, player2Id){
    try{
      
      this.state.monstertoken.events.allEvents()
      .on('data',(event)=>{
        if(event.returnValues[0] == player1Id && event.returnValues[1]){
          window.alert("you win!")
          window.location.reload()
        }else if(event.returnValues[0] == player1Id){
          window.alert("you lose!")
          window.location.reload()
        }
        
      })
      await this.state.monstertoken.methods.battleWithPlayer(player1Id,player2Id).send({from:this.state.account})
    }catch(err){
      if(err){
        window.alert('Unexpected mistake!')
      }
    }
  }

  async battleWithDefault(player1Id, defaultId){
    try{      
      this.state.monstertoken.events.allEvents()
      .on('data',(event)=>{
        if(event.returnValues[0] == player1Id && event.returnValues[1]){
          window.alert("you win!")
          window.location.reload()
        }else if(event.returnValues[0] == player1Id){
          window.alert("you lose!")
          window.location.reload()
        }
      })
      .on('error',console.error)
      await this.state.monstertoken.methods.battleWithDefault(player1Id,defaultId).send({from:this.state.account})

    }catch(err){
      if(err){
        window.alert(err)
      }
    }
  }

  async getBreed(mumID, dadID){
    try{
      await this.state.monstertoken.methods.breed(mumID, dadID).send({from:this.state.account})
      window.alert('You have get a new monster! Refresh to check')
      window.location.reload()
      
    } catch(err) {
      if (err) {
        if(this.getRPCErrorMessage(err) === "revert should have enough money"){
          window.alert( "Sorry, you dont have enough money for this. Please deposit money")

        }else if(this.getRPCErrorMessage(err) === "revert should have the same race"){
          window.alert( "Parents must be in the same races")
        }
        else window.alert(err)
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

  handleCloseForBattleChoose = () =>{
    this.setState({showForBattleChoice:false})
  }

  handleShowForComponent = () =>{
    this.getComponent()
    this.setState({showForBattleChoice:false})
    this.setState({showForComponent:true})
  }

  handleCloseForComponent = () =>{
    this.setState({component:[]})
    this.setState({componentLoading:true})
    this.setState({showForComponent:false})
  }

  handleShowForDefault = () =>{
    this.setState({showForBattleChoice: false})
    this.setState({showForDefault:true})
  }

  handleCloseForDefault= () =>{
    this.setState({showForDefault:false})
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

  handlePlayer1Change = (event) =>{
    this.setState({player1Id:event.target.value})
    this.setState({showForBattleChoice:true})
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

  handleDeleteProduct = (event) =>{
    this.deleteProduct(event.target.value)
  }
  
  handleBattleWithPlayer = (event) =>{
    this.battleWithPlayer(this.state.player1Id,event.target.value)
  }

  handleBattleWithDefault = (event) =>{
    this.battleWithDefault(this.state.player1Id,event.target.value)
  }

  handleDadChange = (event) =>{
    this.setState({dadId:event.target.value})
    
  }

  handleMumChange = (event) =>{
    this.setState({mumId:event.target.value})
  }

  handleSendBreeding = () =>{
    if(this.state.dadId != 0 && this.state.mumId != 0){
      if (this.state.dadId == this.state.mumId) {
        window.alert('You have chosen same dad and mom!')
        window.location.reload()
    }else{
      this.getBreed(this.state.dadId, this.state.mumId)
    }
  }else{
    window.alert("You should choose two parents")
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
                          <div>
                            <p>Exp:{content.exp}/{content.level}0</p>
                          </div>
                          {
                            content.islock
                            ?<div className = "d-flex justify-content-center">
                              <Button variant='outline-primary' value = {content.Id} onClick = {this.handleDeleteProduct}>Get back from market</Button>
                            </div>
                            :
                          <div className = "d-flex justify-content-between">
                              <Button variant='outline-primary' value = {content.Id} onClick = {this.handleChoosedProduct}>Sell</Button>
                              <Button variant='outline-primary' value = {content.Id} onClick = {this.handlePlayer1Change}>Battle with</Button>
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
              <p>Want to breed a new one? (this cost 2 eth)</p>
            </Row>
            {
                this.state.breedings.length < 2
                ?<Row  style={{marginBottom:'10px', marginTop:'10px'}}><p>You should have at least 2 monsters for breeding</p></Row>
                :
                <>
                <Row>
                  <p>Notice</p>

                </Row>
                <Row>
                  <li>
                    You should choose two parent with the same race
                  </li>
                  <li>
                    The attribute HP, Strength, Defensive and Speed are inidividual value instead of actual ability point. Individual value can affect their actual ability when they level up. 

                  </li>
                  <li>
                    When breeding, the child will inherit 3 inidividual values from their parents, and get the value of the last randomly. Individual value cannot be changed after they born.
                  </li>
                </Row>
                <Container>
                  

                  <Row style={{marginBottom:'10px', marginTop:'10px'}}>
                    <Form.Select onChange = {this.handleDadChange}  >
                      <option value = {0}>Choose Dad</option>
                      {this.state.breedings.map((content) =>{
                        return(
                          <option key = {content.Id} value = {content.Id}>
                            Id:{content.Id}||
                            Race:{content.race}||
                            HP:{content.HP}||
                            Strength:{content.strength}||
                            Defensive:{content.defensive}||
                            Speed:{content.speed}
                          </option>
                        )
                      })}
                    </Form.Select>


                  </Row>
                  <Row>
                    <Form.Select  onChange = {this.handleMumChange}  >
                      <option value = {0}>Choose Mum</option>
                      {this.state.breedings.map((content) =>{
                        return(
                          <option key = {content.Id} value = {content.Id}>
                            Id:{content.Id}||
                            Race:{content.race}||
                            HP:{content.HP}||
                            Strength:{content.strength}||
                            Defensive:{content.defensive}||
                            Speed:{content.speed}
                          </option>
                        )
                      })}
                    </Form.Select>
                  </Row>                  
                  <div className = "d-flex justify-content-center">
                    <Button variant='outline-primary' onClick = {this.handleSendBreeding}>Submit</Button>
                  </div>
                </Container>
                </>
              }
            

            <Row style={{marginBottom:'10px', marginTop:'60px'}} md={4}> 
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

            <Modal show = {this.state.showForBattleChoice} onHide = {this.handleCloseForBattleChoose}>
              <Modal.Body>
                <div className = "d-flex w-200 justify-content-between">
                  <Button onClick = {this.handleShowForComponent}>Battle with Player</Button>
                  <Button onClick = {this.handleShowForDefault}>Battle with Default Monster</Button>
                </div>
              </Modal.Body>
              <Modal.Footer>
                <Button variant="secondary" onClick={this.handleCloseForBattleChoose}>
                    Close
                </Button>
              </Modal.Footer>
            </Modal>

            <Modal show = {this.state.showForComponent} onHide = {this.handleCloseForComponent}>
              <Modal.Body>
                <div>
                  {
                    this.state.componentLoading
                    ? <p>Loading...</p>
                    :<>
                    {
                    this.state.component.length == 0
                    ? <p>No available component, your monsters cannot be your component</p>
                    :
                    <div style={{marginTop:"20px",marginBottom:'10px'}} className = "d-flex flex-wrap">
                      {this.state.component.map((content) =>(
                        <a key = {content.Id} className="list-group-item list-group-item-action flex-column align-self-center">
                            <div className="d-flex w-200 justify-content-between">
                              <img src = {content.img} width="100" height="100"/>
                              <small>level {content.level}</small>
                            </div>
                              <div className = "d-flex justify-content-between">
                                <p>id: {content.Id}</p>
                                
                              </div>
                              <div className = "d-flex justify-content-between">
                                <p>HP: {content.HP}</p>
                                <p>strength: {content.strength}</p>
                                <p>defensive: {content.defensive}</p>
                                <p>speed: {content.speed}</p>
                              </div>
                              <div className = "d-flex justify-content-center">
                                <Button value = {content.Id} variant="outline-primary" onClick={this.handleBattleWithPlayer}>Choose</Button>
                              </div>
                          </a>
                      ))}
                    </div> 
                    }
                  </>
                  }
                </div>
              </Modal.Body>
              <Modal.Footer>
                <Button variant="secondary" onClick={this.handleCloseForComponent}>
                    Close
                </Button>
              </Modal.Footer>
            </Modal>

            <Modal show = {this.state.showForDefault} onHide = {this.handleCloseForDefault}>
              <Modal.Body>
                <div style={{marginTop:"20px",marginBottom:'10px'}} className = "d-flex flex-wrap">
                  {this.state.defaultMonster.map((content) =>(
                    <a key = {content.Id} className="list-group-item list-group-item-action flex-column align-self-center">
                        <div className="d-flex w-200 justify-content-between">
                          <img src = {content.img} width="100" height="100"/>
                          <small>level {content.level}</small>
                        </div>
                          <div className = "d-flex justify-content-between">
                            <p>id: {content.Id}</p>
                            
                          </div>
                          <div className = "d-flex justify-content-between">
                            <p>HP: {content.HP}</p>
                            <p>strength: {content.strength}</p>
                            <p>defensive: {content.defensive}</p>
                            <p>speed: {content.speed}</p>
                          </div>
                          <div className = "d-flex justify-content-center">
                            <Button value = {content.Id} variant="outline-primary" onClick={this.handleBattleWithDefault}>Choose</Button>
                          </div>
                      </a>
                  ))}
                </div>
              </Modal.Body>
            </Modal>
          </Container>
        }  
      </div>
    )
  }
}

export default MyMonster;