// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
// import "hardhat/console.sol";

interface Oracle {
    function latestAnswer() external returns (uint256);
    function decimals() external returns (uint8);
}

struct Acc{
	uint256 amount;
	uint256 userTotal;
	uint245 tokenTotal;
}

contract HyperBitCoinalization {
	using SafeERC20Upgradeable for IERC20Upgradeable;

	address public immutable btc;
	address public immutable usdc;
	address public immutable oracle;

	uint immutable conversionRatio;
	uint immutable endTimeStamp;
	address owner;

	mapping (address => Acc[]) btcAcc;
	mapping (address => Acc[]) usdcAcc;

	mapping (address => uint) btcBalance;
	mapping (address => uint) usdcBalance;

	uint256 public btcTotal;
	uint256 public usdcTotal;

	address winnerToken;

	// duration is in form of days
	constructor(address _btc, address _usdc, address _oracle, uint _conversionRatio, uint _endTimeStamp) {
		btc = _btc;
		usdc = _usdc;
		oracle = _oracle;

		conversionRatio = _conversionRatio;
		endTimeStamp = _endTimeStamp;

		btcTotal = 0;
		usdcTotal = 0;

		owenr = msg.sender;
	}

	function pushToAcc(Acc[] _acc, Acc) private {
		_acc.push(Acc);
	}

	function depositBTC(uint amount) payable public {
		// transfer BTC to contract
		IERC20Upgradeable(btc).safeTransfer(address(this), amount);
		
		// update balances
		btcBalance[msg.sender] += amount;
		btcTotal += amount;

		// update user BTC accumulator
		pushToAcc(btcAcc[msg.sender], Acc(amount, btcBalance, btcTotal));

	}

	function depositUSDC(uint amount) external payable {
		// transfer USDC to contract
		IERC20Upgradeable(usdc).safeTransfer(address(this), amount);

		// update balances
		usdcBalance[msg.sender] += amount;
		usdcTotal += amount;

		// update user USDC accumulator
		pushToAcc(usdcAcc[msg.sender], Acc(amount, usdcBalance[msg.sender], usdcTotal));

	}

		

	
}
