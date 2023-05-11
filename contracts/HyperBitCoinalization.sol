// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "openzeppelin-contracts/utils/math/Math.sol";
// import "hardhat/console.sol";

interface Oracle {
    function latestAnswer() external returns (uint256);
    function decimals() external returns (uint8);
}

struct Acc{
	uint256 amount;
	uint256 userTotal;
	uint256 tokenTotal;
}

contract HyperBitCoinalization {
	using SafeERC20Upgradeable for IERC20Upgradeable;

	address public immutable btc;
	address public immutable usdc;
	address public immutable oracle;

	uint immutable conversionRatio;
	uint immutable endTimeStamp;

	address public immutable owner;

	mapping (address => Acc[]) btcAcc;
	mapping (address => Acc[]) usdcAcc;

	mapping (address => uint) btcBalance;
	mapping (address => uint) usdcBalance;

	mapping (address => bool) claimed;

	uint256 public btcTotal;
	uint256 public usdcTotal;

	address winnerToken;

	constructor(address _btc, address _usdc, address _oracle, uint _conversionRatio, uint _endTimeStamp) {
		btc = _btc;
		usdc = _usdc;
		oracle = _oracle;

		conversionRatio = _conversionRatio;
		endTimeStamp = _endTimeStamp;

		btcTotal = 0;
		usdcTotal = 0;
	}

	function depositBTC(uint amount) external {
		// transfer BTC to contract
		IERC20Upgradeable(btc).safeTransferFrom(msg.sender, address(this), amount);
		
		// update balances
		btcBalance[msg.sender] += amount;
		btcTotal += amount;

		// update user BTC accumulator
		btcAcc[msg.sender].push(Acc(amount, btcBalance, btcTotal));

	}

	function depositUSDC(uint amount) external {
		// transfer USDC to contract
		IERC20Upgradeable(usdc).safeTransferFrom(msg.sender, address(this), amount);

		// update balances
		usdcBalance[msg.sender] += amount;
		usdcTotal += amount;

		// update user USDC accumulator
		usdcAcc[msg.sender].push(Acc(amount, usdcBalance[msg.sender], usdcTotal));

	}

	function btcInBet() public view returns (uint256) {
		return _btcInBet(msg.sender);
	}

	function usdcInBet() public view returns (uint256) {
		return _usdcInBet(msg.sender);
	}

	function _btcInBet(address sender) internal returns (uint256) {
		// TODO: error handling
		uint256 _btc = Math.min(btcTotal, usdcTotal / conversionRatio);
		return binarySearch(_btc, btcAcc[sender]);
	}

	function _usdcInBet(address sender) internal returns (uint256) {
		// TODO: error handling
		uint256 _usdc = Math.min(usdcTotal, usdcTotal * conversionRatio);
		return binarySearch(_usdc, usdcAcc[sender]);
	}

	function binarySearch(uint256 total, Acc[] memory acc) internal returns (uint 256){
		uint len = acc.length;
		uint start = 0;
		uint end = len - 1;

		if(len == 0) return 0;

		while(start < end){
			uint mid = (start + end)/2;
			
			if(acc[mid].tokenTotal - acc[mid].amount < total){
				start = mid + 1;
			}else{
				end = mid;
			}
		}

		if(acc[start].tokenTotal <= total){
			return acc[start].userTotal;
		}
		uint diff = total - acc[start].tokenTotal;
		return acc[start].userTotal - diff;
	}

	function setWinnerToken() public {
		if(winnerToken != address(0)) return;
		
		uint8 decimals = Oracle(oracle).decimals();
		uint256 answer = Oracle(oracle).latestAnswer();
		uint256 treshold = conversionRatio * 10 ** decimals;

		if(answer >= treshold) winnerToken = btc;
		else if(block.timestamp >= endTimeStamp) winnerToken = usdc;
	}

	function claim() external {
		if(winnerToken == address(0)) return;
		if(claimed[msg.sender]) return;

		if(winnerToken == btc){
			uint256 btcAmount = _btcInBet(msg.sender);
			IERC20Upgradeable(btc).safeTransfer(btcAmount);
			IERC20Upgradeable(usdc).safeTransfer(btcAmount * conversionRatio);
		}else if(winnerToken == usdc){
			uint256 usdcAmount = _usdcInBet(msg.sender);
			IERC20Upgradeable(usdc).safeTransfer(usdcAmount);
			IERC20Upgradeable(btc).safeTransfer(usdcAmount / conversionRatio);
		}
		
		claimed[msg.sender] = true;
	}
}
