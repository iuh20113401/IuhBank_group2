import React from "react";
import LoginForm from "./Login"
import Admin from "./admin"
import User from "./User"
import Slider from "./slider";
import io from 'socket.io-client';
import Header from './header';
import {
    BrowserRouter as Router,
    Route,
    BrowserRouter
}from "react-router-dom"
import { Routes  } from 'react-router-dom'
const socket = io('https://iuh-bank-server.onrender.com');
function App ()  {
      return(
        <div>
          <Header/>
        <Router>
          <Routes>
          <Route path ='/' element ={<Slider/>}/>
          <Route  path ='/login' element={<LoginForm socket = {socket}/>}/>
          <Route path = '/admin' element = {<Admin socket = {socket}/>} />
          <Route path = '/user' element ={<User socket = {socket}/>} />
        </Routes>
        </Router>
        </div>
      )
}

export default App;
