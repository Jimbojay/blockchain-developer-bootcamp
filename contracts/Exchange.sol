// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "./Token.sol";

contract Exchange {
	address public feeAccount;
	uint256 public feePercent;
	mapping(address => mapping(address => uint256)) public tokens;
	mapping(uint256 => _Order) public orders; //Orders Mapping
	uint256 public orderCount;
	mapping(uint256 => bool) public orderCancelled;
	mapping(uint256 => bool) public orderFilled;

	event Deposit(
		address token, 
		address user, 
		uint256 amount, 
		uint256 balance
	);

	event Withdraw(
		address token,
		address user,
		uint256 amount,
		uint256 balance
	);

	event Order(
		//Attributes of an oder
		uint256 id, //Unique identifier for order
		address user, // User who made order
		address tokenGet, //Address of the token they receive
		uint256 amountGet, //Amount they receive
		address tokenGive, //Address ot the token they give
		uint256 amountGive, //Amount they give
		uint256 timestamp //When order was created
	);

	event Cancel(
		uint256 id, //Unique identifier for order
		address user, // User who made order
		address tokenGet, //Address of the token they receive
		uint256 amountGet, //Amount they receive
		address tokenGive, //Address ot the token they give
		uint256 amountGive, //Amount they give
		uint256 timestamp //When order was created	
	);

	event Trade(
		uint256 id, //Unique identifier for order
		address user, // User who made order
		address tokenGet, //Address of the token they receive
		uint256 amountGet, //Amount they receive
		address tokenGive, //Address ot the token they give
		uint256 amountGive, //Amount they give
		address creator,
		uint256 timestamp //When order was created	
	);

	struct _Order{
		//Attributes of an oder
		uint256 id; //Unique identifier for order
		address user; // User who made order
		address tokenGet; //Address of the token they receive
		uint256 amountGet; //Amount they receive
		address tokenGive; //Address ot the token they give
		uint256 amountGive; //Amount they give
		uint256 timestamp; //When order was created
	}

	constructor(address _feeAccount, uint256 _feePercent) {
		feeAccount = _feeAccount;
		feePercent = _feePercent;
	}

	// ------------------------
	// Deposit & withdraw tokens
	// ------------------------
	function depositToken(address _token, uint256 _amount) public {
		//Transfer tokens to exchange
		require(Token(_token).transferFrom(msg.sender, address(this), _amount));

		//Update balance 
		tokens[_token][msg.sender] = tokens[_token][msg.sender] + _amount;

		//Emit event
		emit Deposit(_token, msg.sender, _amount, tokens[_token][msg.sender]);
	}

	function withdrawToken(address _token, uint256 _amount) public {
		//Ensure user has enough to withdrwa
		require(tokens[_token][msg.sender] >= _amount);


		//Transfer tokens to user
		Token(_token).transfer(msg.sender, _amount);

		//Update user balance
		tokens[_token][msg.sender] = tokens[_token][msg.sender] - _amount;

		//Emit event
		emit Withdraw(_token, msg.sender, _amount, tokens[_token][msg.sender]);

	}

	// Check balances
	function balanceOf(address _token, address _user)
		public
		view
		returns (uint256)
	{
		return tokens[_token][_user];
	}

	// ------------------------
	// MAKE & CANCEL ORDERE
	// ------------------------

	function makeOrder(
		address _tokenGet, 
		uint256 _amountGet, 
		address _tokenGive, 
		uint256 _amountGive
	) public {
		require(balanceOf(_tokenGive, msg.sender) >= _amountGive);

		orderCount++;
		orders[orderCount] = _Order(
			orderCount, //id
			msg.sender, //user
			_tokenGet, //tokenGet
			_amountGet, //amountGet
			_tokenGive, //tokenGive
			_amountGive, //amountGive
			block.timestamp //timestamp '1/1/2030 01:01:01' 1893507958 epox unix time
		);

		emit Order(
			orderCount,
			msg.sender,
			_tokenGet,
			_amountGet,
			_tokenGive,
			_amountGive,
			block.timestamp
		);	
	}

	function cancelOrder(uint256 _id) public {

		//Fetch order
		_Order storage _order =  orders[_id];

		//ensure that caller owner of order
		require(address(_order.user) == msg.sender);

		//order must exist
		require(_order.id == _id);

		orderCancelled[_id] = true;

		emit Cancel(
			_order.id,
			msg.sender,
			_order.tokenGet,
			_order.amountGet,
			_order.tokenGive,
			_order.amountGive,
			block.timestamp

		);
	}

	//----------------
	// EXCECUTING ORDERS

	function fillOrder (uint256 _id) public {
		//1. Must be a valid orderId
		require(_id > 0 && _id <= orderCount, "Order does not exist");
		//2. Order can't be filled
		require(!orderFilled[_id]);
		//3. Order can't be cancelled
		require(!orderCancelled[_id]);


		//Fetch order
		_Order storage _order =  orders[_id];

		//Execute the trade
		_trade(
			_order.id,
			_order.user,
			_order.tokenGet,
			_order.amountGet,
			_order.tokenGive,
			_order.amountGive
		);

		//Mark order as filled
		orderFilled[_order.id] = true;
	}
	
	function _trade(
		uint256 _orderId,
		address _user,
		address _tokenGet,
		uint256 _amountGet,
		address _tokenGive,
		uint256 _amountGive
	) internal {

		uint256 _feeAmount = (_amountGet * feePercent) / 100;

		tokens[_tokenGet][msg.sender] = tokens[_tokenGet][msg.sender] - (_amountGet + _feeAmount);
		tokens[_tokenGet][_user] = tokens[_tokenGet][_user] + _amountGet;

		tokens[_tokenGet][feeAccount] = tokens[_tokenGet][feeAccount] + _feeAmount; 

		tokens[_tokenGive][_user] = tokens[_tokenGive][_user] - _amountGive;
		tokens[_tokenGive][msg.sender] = tokens[_tokenGive][msg.sender] + _amountGive ;

		emit Trade(
			_orderId,
			msg.sender,
			_tokenGet,
			_amountGet,
			_tokenGive,
			_amountGive,
			_user,
			block.timestamp
		);

	}

	// Depostit tokens - X
	// Withdraw tokens - X
	// Check balances - X
	// Make orders - X
	// Cancel orders - X
	// Fill orders
	// Charge fees
	// Track fee account - X

}
