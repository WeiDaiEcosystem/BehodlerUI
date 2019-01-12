pragma solidity ^0.5.0;
import "../node_modules//openzeppelin-solidity/contracts/ownership/Secondary.sol";
import "../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";
import "../node_modules//openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";
import "./Updai.sol";

/*
* last person to burn gets 60%
* if the last burn < previous then timer has 30 mins added to clock. 
* if higher, nothing added to clock.
 */
contract EpochGame is Secondary {
	uint epochDuration;
	uint currentEpoch;
	uint currentEpochBlock;
	using SafeMath for uint256;
	address UpdaiAccount;
	mapping (address=>uint) winners;
	mapping (address=> uint) refunds;
	mapping (address => uint) lastEpochPlayed; //cannot withdraw if currently playing for safety reasons
	uint lastEpochSettled;

	function setDependencies(address updai) public onlyPrimary {
		UpdaiAccount = updai;
	}

	constructor () public {
		currentEpochBlock = block.number;
	}

	function setEpochDuration (uint blocks) public onlyPrimary{
		epochDuration = blocks;
	}

	function getCurrentEpoch() public returns (uint) {
		uint blocksSinceLastEpoch = block.number.sub(currentEpochBlock);
		if(blocksSinceLastEpoch < epochDuration)
			return currentEpoch;
		
		uint epochsElapsed = blocksSinceLastEpoch.div(currentEpochBlock);
		currentEpoch = currentEpoch.add(epochsElapsed);
		currentEpochBlock = currentEpochBlock.add(epochsElapsed.mul(epochDuration));
	}

	function _settleEpoch(uint epochNumber) internal {
		require(epochNumber<currentEpoch, "cannot settle future epochs");
		lastEpochSettled = epochNumber;
	}

	function _enter(uint updai, address player) internal { // call first
		address self = address(this);
		require (ERC20(UpdaiAccount).allowance(player,self)>=updai,"epoch game unauthorized to take dai");
		ERC20(UpdaiAccount).transferFrom(player, address(this),updai);
		lastEpochPlayed[player] = currentEpoch;
		refunds[msg.sender] += updai;
	}

	function withDraw() public {
		require(lastEpochPlayed[msg.sender]<lastEpochSettled, "cannot withdraw while entered into an unsettled game");
		if(winners[msg.sender]>0){
			uint amountToWithdraw = winners[msg.sender];
			winners[msg.sender] = 0;
			ERC20(UpdaiAccount).transfer(msg.sender, amountToWithdraw);
		}
		if(refunds[msg.sender]>0) {
			uint amountToWithdraw = refunds[msg.sender];
			refunds[msg.sender] = 0;
			ERC20(UpdaiAccount).transfer(msg.sender, amountToWithdraw);
		}
	}
}