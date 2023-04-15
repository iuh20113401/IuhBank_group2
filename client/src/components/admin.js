import { Tabs, Tab } from 'react-bootstrap'
import Col from 'react-bootstrap/Col'
import Nav from 'react-bootstrap/Nav'
import Row from 'react-bootstrap/Row'
import dBank from '../abis/dBank.json'
import React, { Component,useState } from 'react';
import Token from '../abis/Token.json'
import Web3 from 'web3';
import {adminAccount} from './adminaccount';
import {BrowserRouter as Router, Navigate }from "react-router-dom"
import Modal from 'react-bootstrap/Modal';
import Button from 'react-bootstrap/Button';
let room = '';
let user = JSON.parse(localStorage.getItem('user'))||[];
let userStake =[];
let modal = localStorage.getItem('modal') || ('');
export default class Begin extends Component{
  render (){
    if(adminAccount === 2){
      return <Admin socket = {this.props.socket}/>
    }
    return <Navigate to="/" />}
}
function ModalShow(props){
  const [show, setShow] = useState(true);
  const handleClose = () => setShow(false);
  const Reload = () =>{
    setShow(false);
  }
  const message = props.message
  localStorage.removeItem("modal");
  return(
    <>
      <Modal show={show} onHide={handleClose}>
        <Modal.Header closeButton>
          <Modal.Title className = "text-center" >Thông báo</Modal.Title>
        </Modal.Header>
        <Modal.Body className ="text-center" ><h5>{message}</h5></Modal.Body>
        <Modal.Footer>
          <Button variant="primary" onClick={Reload}>
            Xác nhận
          </Button>
        </Modal.Footer>
      </Modal>
    </>)
}
class Admin extends Component{ 
  async loadBlockchainData(dispatch) {
    if(typeof window.ethereum !== 'undefined'){
      const web3 = new Web3(window.ethereum)
      const netId = await web3.eth.net.getId()
      const accounts = await web3.eth.getAccounts()
      const account =[];
      
      if(typeof accounts[0] !== 'undefined'){
        const balance = await web3.eth.getBalance(accounts[0])
        this.setState({account: accounts[0], balance: balance, web3: web3})
      } else {
        window.alert('Please login with MetaMask')
      }
      try {
        const token = new web3.eth.Contract(Token.abi, Token.networks[netId].address)
        const dbank = new web3.eth.Contract(dBank.abi, dBank.networks[netId].address)
        const dBankAddress = dBank.networks[netId].address
        this.setState({token: token, dbank: dbank, dBankAddress: dBankAddress})
        await this.getStaker();
        this.setState({ connect: true });;
      } catch (e) {
            console.log('Error', e)
            window.alert('Contracts not deployed to the current network')
            this.state.connect = true;
          }
    } else {
      window.alert('Please install MetaMask')
    }
  }
  componentDidMount() {
    this.loadBlockchainData()
    fetch('http://localhost:3000/admin', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({account: this.state.account}),
  })
    .then((res) => {
      if (!res.ok) {
        throw new Error('Network response was not ok');
      }
      return res.json();
    })
    .then((data) => {
      console.log(data);
      localStorage.setItem('user',JSON.stringify(data));
      user = JSON.parse(localStorage.getItem('user'));
      if(user.length != 0){
      localStorage.setItem('modal',"Bạn có yêu cầu đặt cọc");}
    })
    .catch((error) => {
      window.location.reload();
    });
  }
  async getStaker(){
    let stateAmount = 0;
    let stakeAmount = await this.state.dbank.methods.getStaker().call({from:this.state.account});
    for(let i = 0; i < stakeAmount.length; i++){
      let staker = await this.state.dbank.methods.getStakerInfo(stakeAmount[i]).call({from:this.state.account});
      let j = 0;
      for(j ; j <= staker.index; j++){
          this.state.staker.push({account: stakeAmount[i],index: j, value: staker.stakeBalanceOf[j],method: staker.stakeMethod[j]})
          if(j == staker.idnex){
            break;
          }
      }
      console.log(this.state.staker)
    }
  }
  async withstake(address,index) {
    if(this.state.dbank!=='undefined'){
      try{
        // dùng để lấy ether từ account đang liên kết vào tiền gửi
        await this.state.dbank.methods.withState(address,index).send({from: this.state.account})
        localStorage.setItem('modal',"Bạn trả tiền cọc thành công");
        window.location.reload()
      } catch (e) {
        // báo lỗi nếu việc lấy giá trị bị lỗi
        alert('ban khong co tien dat coc');
      }
    }
  }
  async withStateToken(address) {
    if(this.state.dbank!=='undefined'){
      try{
        // dùng để lấy ether từ account đang liên kết vào tiền gửi
        await this.state.dbank.methods.withStateToken(address).send({from: this.state.account})
        localStorage.setItem('modal',"Bạn trả tiền cọc thành công");
        window.location.reload()
      } catch (e) {
        // báo lỗi nếu việc lấy giá trị bị lỗi
        alert('ban khong co tien dat coc');
      }
    }
  }
  constructor(props) {
    super(props)
    this.state = {
      web3: 'undefined',
      account: '',
      token: null,
      dbank: null,
      balance: 0,
      dBankAddress: null,
      staker: [],
      stateAmount: 0,
      connect: false
    }
  }
  async SendRequest(amount,id){
    {this.props.socket.emit('userValue',{
    value : amount,
    id: id
    })};
    localStorage.setItem('modal',"Bạn gửi yêu cầu thành công");
    window.location.reload();
  }
  Reload(){
    window.location.reload();
  }
  render() {
    return (
    <div >
      {modal !== '' && <ModalShow message = {modal} />}
      <div  className='text-monospace' >
        {this.state.connect == false && <div ></div>}
        {this.state.connect == true && <div>
          <div className="container-fluid mt-5 text-center">
            <br></br>
            <h1>Welcome to IUHBANK</h1>
            <h2>You are admin</h2>
            <br></br>
            <div className="row">
              <main role="main" className="col-lg-12 d-flex text-center w-100">
                <div className="content mr-auto ml-auto w-100">
                  <Tab.Container id="left-tabs-example" defaultActiveKey="first">
                    <Row>
                      <Col xs={3}>
                                <Nav variant="pills" className=" text-left flex-column">
                                  <Nav.Item>
                                    <Nav.Link eventKey="first">Yêu cầu cọc tiền</Nav.Link>
                                  </Nav.Item>
                                  <Nav.Item>
                                    <Nav.Link eventKey="second">Quản lý tiền cọc</Nav.Link>
                                  </Nav.Item>
                                </Nav>
                      </Col>
                      <Col xs={9}>
                                <Tab.Content>
                                  <Tab.Pane eventKey ='first'>
                                    <form >
                                      {console.log(user.length)}
                                      {(user.length != 0) && user.map(user => (
                                        <div>
                                          <div className='form-group mr-sm-2'>
                                            <br></br>
                                            <input 
                                              type='text'
                                              className="form-control form-control-md"
                                              placeholder= {user.id}
                                              disabled />
                                            <br></br>
                                            <input
                                              id='ether'
                                              type='number'
                                              ref={(input) => { this.ether = input }}
                                              className="form-control form-control-md"
                                              placeholder='Số tiền cần cọc...'
                                              required />
                                          </div>
                                          <button type='button' className='btn btn-primary' onClick={(e) =>{
                                            let amount = this.ether.value
                                            this.SendRequest(amount,user.id)
                                          }} >Gửi yêu cầu</button></div>
                                      ))}
                                      <br></br>
                                      <button type='button' onClick={this.Reload.bind(this)}  className='btn btn-primary' >Refresh</button>
                                    </form>
                                  </Tab.Pane>
                                  <Tab.Pane eventKey = 'second'>
                                    {this.state.staker != [] && this.state.staker.map( staker => <div>
                                    {(staker.value != 0) && 
                                      <form>
                                        {console.log("staker: ", staker)}
                                          <input
                                            type='text'
                                            value= {staker.account}
                                            className="form-control form-control-md"
                                            disabled/>
                                          <br></br>
                                          <input
                                          type='number'
                                          value= {staker.value / (10 ** 18)}
                                          className="form-control form-control-md"
                                          disabled/>
                                          <br></br>
                                          <input
                                          type='text'
                                          value= {staker.method}
                                          className="form-control form-control-md"
                                          disabled/>
                                          <br></br>
                                          <button type='button' className='btn btn-primary' onClick={(e) =>{
                                            this.withstake(staker.account,staker.index);}
                                          }>Trả tiền cọc</button>
                                      </form>
                                      }</div>)
                                    }
                                    <br></br>
                                    <button type='button' className='btn btn-primary' onClick={this.Reload}>Refresh</button>
                                  </Tab.Pane>
                                </Tab.Content>
                      </Col>
                    </Row>
                  </Tab.Container>
                </div>
              </main>
            </div>
          </div>
        </div>}
      </div>
    </div>
    );
  }
}


