// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;
pragma abicoder v2;
//giống import trong python
import "./Token.sol";

// tạo ra Smart contract tên là dBank
contract dBank {
  Token private token;
  struct staker{
    uint index;
    uint[] stakeBalanceOf;
    uint[] stakeStart;
    string[] stakeMethod;
  }
  struct user{
    uint etherBalanceOf;
    uint TokenBalanceOf;
    // các biến mượn tiền
    uint borrowIndex;
    address[] borrower;
    uint[] borrowAmount;
    uint[] borrowInterest;
    uint[] borrowerPayOffAmount;
    string[] borrowMethod;
    //Các biến cho mượn tiền
    uint lenderIndex;
    address[] lender;
    uint[] lendAmount;
    uint[] lendInterest;
    uint[] lenderPayOffAmount;
    string[] lendMethod;
    
  }
  
  address payable public receiver;
  address[] public stakerAddress;
  mapping(address => staker) private stakerInfo ;
  mapping(address => user) public userInfo;
  uint PayOffAmount;
  mapping(address => bool) public isStake;
  mapping(address => bool) public staked;
  
  mapping(address => bool) public isDeposited;

  constructor(Token _token) public {
  token = _token;
  }
  
  // Khai báo một hàm dùng để gửi tiền gủi
  function deposit() payable public {
    require(msg.value>=1e16, 'Error, deposit must be >= 0.01 ETH');

    userInfo[msg.sender].etherBalanceOf += msg.value; 
    isDeposited[msg.sender] = true; //activate deposit status
  }

  // khai báo một hàm dùng để rút tiền cộng với tiền lãi
  function withdraw() payable public {
    require(isDeposited[msg.sender]==true, 'Error, no previous deposit');

    uint userBalance = userInfo[msg.sender].etherBalanceOf; 

    payable(msg.sender).transfer(msg.value); 
    userInfo[msg.sender].etherBalanceOf -= msg.value;
    if(userInfo[msg.sender].etherBalanceOf == 0){
      isDeposited[msg.sender] = false;
    }
  }

  //khai báo một hàm dùng để đặt tiền cọc bằng tiền gửi trong ngân hàng từ trước
  function CocWithEtherDeposit(uint amount) payable public {
    require(userInfo[msg.sender].etherBalanceOf >= amount, 'Error, deposit already active');

    if(staked[msg.sender] == false){
    stakerAddress.push(msg.sender);
    stakerInfo[msg.sender].index = 0;
    }else{
      stakerInfo[msg.sender].index += 1;}
    
    stakerInfo[msg.sender].stakeBalanceOf.push(amount);
    stakerInfo[msg.sender].stakeStart.push(block.timestamp);
    stakerInfo[msg.sender].stakeMethod.push("Ether");
    isStake[msg.sender] = true; 
    staked[msg.sender] = true;
  }

  //khai báo một hàm dùng để đặt tiền cọc bằng tiền trực tiếp từ ví 
  function Coc() payable public {
    require(msg.value>=1e16, 'Error, stake must be >= 0.01 ETH');
    if(staked[msg.sender] == false){
    stakerAddress.push(msg.sender);
    stakerInfo[msg.sender].index = 0;
    }else{
      stakerInfo[msg.sender].index += 1;
    }
    stakerInfo[msg.sender].stakeBalanceOf.push(msg.value);
    stakerInfo[msg.sender].stakeStart.push(block.timestamp);
    stakerInfo[msg.sender].stakeMethod.push("Ether");
    isStake[msg.sender] = true; 
    staked[msg.sender] = true;
  }
  // khai báo một hàm dùng để đặt cọc bằng token
  function CocWithToken(uint amount) payable public {
    require(userInfo[receiver].TokenBalanceOf >=  amount,"ban khong co du token de cho muon");
    token.transferFrom(msg.sender, address(this), amount);
    if(staked[msg.sender] == false){
    stakerAddress.push(msg.sender);
    stakerInfo[msg.sender].index = 0 ;
    }else{
      stakerInfo[msg.sender].index += 1;
    }
    stakerInfo[msg.sender].stakeBalanceOf.push(amount * (10 ** 18));
    stakerInfo[msg.sender].stakeStart.push(block.timestamp);
    stakerInfo[msg.sender].stakeMethod.push("Token");
    isStake[msg.sender] = true; 
    staked[msg.sender] = true;
  }

  // khai báo hàm với để có thể trả lại tiền cọc cho sinh viên
  function withState(address payable receiver, uint index)  public {
    require(isStake[receiver] == true, "Ban khoong co tien dat coc");
    uint stakeBalance = stakerInfo[receiver].stakeBalanceOf[index]; //for event
    uint TokenMint = stakeBalance * 10**18;
    uint time = block.timestamp - stakerInfo[receiver].stakeStart[index];
    if(time > 30){
      stakeBalance -= stakeBalance / 2;
      TokenMint = stakeBalance * 10 ** 18;
      payable(msg.sender).transfer(stakeBalance);
    }
    token.mint(receiver, TokenMint);
    receiver.transfer(stakeBalance); //eth back to user
    stakerInfo[receiver].stakeBalanceOf[index] = 0;// tiền gửi bằng 0
    stakerInfo[receiver].stakeStart[index] = 0;
    userInfo[receiver].TokenBalanceOf += TokenMint;
    isStake[receiver] = false;// trạng thái gửi tiền 0
  }
  function withStateToken(address payable receiver, uint index)  public {
    require(isStake[receiver] == true, "Ban khoong co tien dat coc");
    uint stakeBalance = stakerInfo[receiver].stakeBalanceOf[index]; //for event
    uint TokenMint = stakeBalance * 10**18;
    uint time = block.timestamp - stakerInfo[receiver].stakeStart[index];
    if(time > 30){
      stakeBalance -= stakeBalance / 2;
      TokenMint = stakeBalance * 10 ** 18;
    }
    token.mint(receiver, TokenMint);
    stakerInfo[receiver].stakeBalanceOf[index] = 0;// tiền gửi bằng 0
    stakerInfo[receiver].stakeStart[index] = 0;   
    userInfo[receiver].TokenBalanceOf += TokenMint;
    isStake[receiver] = false;// trạng thái gửi tiền 0
  }

  function lendToken(address payable receiver, uint interested) payable public {
    require(userInfo[msg.sender].TokenBalanceOf >= msg.value,"ban khong co du token de cho muon");
    token.transferFrom(msg.sender, receiver, msg.value);
    userInfo[msg.sender].TokenBalanceOf -= msg.value;
    userInfo[receiver].TokenBalanceOf += msg.value;
    uint payOf = msg.value + ((msg.value * interested) / 100);

    userInfo[msg.sender].borrowIndex += 1;
    userInfo[msg.sender].borrower.push(receiver);
    userInfo[msg.sender].borrowAmount.push(msg.value);
    userInfo[msg.sender].borrowerPayOffAmount.push(payOf);
    userInfo[msg.sender].borrowInterest.push(interested);
    userInfo[msg.sender].borrowMethod.push("Token");

    userInfo[receiver].lenderIndex += 1;
    userInfo[receiver].lender.push(msg.sender);
    userInfo[receiver].lendAmount.push(msg.value);
    userInfo[receiver].lendInterest.push(interested);
    userInfo[receiver].lenderPayOffAmount.push(payOf);
    userInfo[receiver].lendMethod.push("Token");
  }

  function lendEther(address payable receiver, uint256 amount, uint interested) payable public{
    require(userInfo[msg.sender].etherBalanceOf >= amount,"khong du tien");
    userInfo[msg.sender].etherBalanceOf -= amount;
    userInfo[receiver].etherBalanceOf += amount;
    uint  payOf = amount + ((amount * interested) / 100);

    userInfo[msg.sender].borrowIndex += 1;
    userInfo[msg.sender].borrower.push(receiver);
    userInfo[msg.sender].borrowAmount.push(amount);
    userInfo[msg.sender].borrowInterest.push(interested);
    userInfo[msg.sender].borrowerPayOffAmount.push(payOf);
    userInfo[msg.sender].borrowMethod.push("Ether");

    userInfo[receiver].lenderIndex += 1;
    userInfo[receiver].lender.push(msg.sender);
    userInfo[receiver].lendAmount.push(amount);
    userInfo[receiver].lendInterest.push(interested);
    userInfo[receiver].lenderPayOffAmount.push(payOf);
    userInfo[receiver].lendMethod.push("Ether");
    }

    function lendEtherDerectly(address payable receiver, uint interested) payable public{
    userInfo[msg.sender].borrowIndex += 1;
    userInfo[msg.sender].borrower.push(receiver);
    uint payOf = msg.value + ((msg.value * interested) / 100);
    userInfo[msg.sender].borrowAmount.push(msg.value);
    userInfo[msg.sender].borrowInterest.push(interested);
    userInfo[msg.sender].borrowMethod.push("Ether");
    userInfo[msg.sender].borrowerPayOffAmount.push(payOf);

    userInfo[receiver].lenderIndex += 1;
    userInfo[receiver].lender.push(msg.sender);
    userInfo[receiver].lendAmount.push(msg.value);
    userInfo[receiver].lendInterest.push(interested);
    userInfo[receiver].lenderPayOffAmount.push(payOf);
    userInfo[receiver].lendMethod.push("Ether");
    receiver.transfer(msg.value);
  }
  function payOffEther(address payable receiver,uint amount, uint index) payable public{
    for(uint i = 0; i < userInfo[receiver].lenderIndex; i++){
        if(userInfo[receiver].borrower[i] == msg.sender){
            userInfo[receiver].borrowAmount[i] = 0;
            userInfo[receiver].borrowInterest[i] = 0;
            userInfo[receiver].borrowerPayOffAmount[i] = 0;
            break;
        }
    }
    userInfo[msg.sender].lendAmount[index] = 0;
    userInfo[msg.sender].lendInterest[index] = 0;
    userInfo[msg.sender].lenderPayOffAmount[index] = 0;
    receiver.transfer(amount);
  }
  function payOffToken(address payable receiver,uint amount, uint index) payable public{
    for(uint i = 0; i < userInfo[receiver].lenderIndex; i++){
        if(userInfo[receiver].borrower[i] == msg.sender){
            userInfo[receiver].borrowAmount[i] = 0;
            userInfo[receiver].borrowInterest[i] = 0;
            userInfo[receiver].borrowerPayOffAmount[i] = 0;
            break;
        }
    }
    userInfo[msg.sender].lendAmount[index] = 0;
    userInfo[msg.sender].lendInterest[index] = 0;
    userInfo[msg.sender].lenderPayOffAmount[index] = 0;
    token.transferFrom(msg.sender, receiver, amount);
  }
  function getStaker() public view returns(address[] memory allStaker){
    allStaker = stakerAddress;
  }
  function getStakerInfo(address stakerAddr) public view returns (uint  index, uint[] memory stakeBalanceOf, string[] memory stakeMethod) {
    index = stakerInfo[stakerAddr].index;
    stakeBalanceOf = stakerInfo[stakerAddr].stakeBalanceOf;
    stakeMethod = stakerInfo[stakerAddr].stakeMethod;
  }
  function getUserInfo(address userAddr) public view returns (
  uint etherBalance,
  uint  tokenBalance,
  uint borrowIndex,
  uint lendIndex
) {
  etherBalance = userInfo[userAddr].etherBalanceOf;
  tokenBalance = userInfo[userAddr].TokenBalanceOf;
  borrowIndex = userInfo[userAddr].borrowIndex;
  lendIndex = userInfo[userAddr].lenderIndex;
}

  function getBorrowInfo(address userAddr) public view returns(address[] memory borrower,
    uint[] memory borrowAmount,
    uint[] memory borrowInterest,
    uint[] memory borrowerPayOffAmount,
    string[] memory borrowMethod){
    borrower = userInfo[userAddr].borrower;
    borrowAmount = userInfo[userAddr].borrowAmount ;
    borrowerPayOffAmount = userInfo[userAddr].borrowerPayOffAmount;
    borrowInterest = userInfo[userAddr].borrowInterest ;
    borrowMethod = userInfo[userAddr].borrowMethod;
  }
  function getLendInfo(address userAddr) public view returns(address[] memory lender,
    uint[]  memory lendAmount,
    uint[] memory lendInterest,
    uint[] memory lenderPayOffAmount,
    string[] memory lendMethod){
    lender = userInfo[userAddr].lender;
    lendAmount = userInfo[userAddr].lendAmount ;
    lendInterest = userInfo[userAddr].lendInterest ;
    lenderPayOffAmount = userInfo[userAddr].lenderPayOffAmount;
    lendMethod = userInfo[userAddr].lendMethod;
  }
  }