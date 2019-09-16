pragma solidity  0.5;
import "../node_modules/openzeppelin-solidity/contracts/ownership/Secondary.sol";
import "../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";
import "../node_modules/openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";
import "./WeiDai.sol";
import "./PatienceRegulationEngine.sol";
import "./baseContracts/Versioned.sol";

contract WeiDaiBank is Secondary, Versioned {

	address donationAddress;
	address self;
	uint lastKnownExchangeRate;
	mapping (address => mapping (address=> uint)) redeemDelegateReward;

	using SafeMath for uint;

	constructor() public{
		self = address(this);
		lastKnownExchangeRate = 100; //1 weidai == 1 US cent.
	}

	function setDonationAddress(address donation) public onlyPrimary {
		donationAddress = donation;
	}

	function getDonationAddress () external view returns (address) {
		return donationAddress;
	}

	function daiPerMyriadWeidai() public view returns (uint) {
		uint totalWeiDai = WeiDai(getWeiDai()).totalSupply();
		
		if(totalWeiDai == 0){
			return lastKnownExchangeRate;
		}
		return ERC20(getDai()).balanceOf(self)
		.mul(10000) //scale by a myriad
		.div(WeiDai(getWeiDai()).totalSupply());
	}

	function issue(address sender, uint weidai, uint dai) external { //sender is dai holder, msg.sender is calling contract
		require(msg.sender == getPRE(), "only patience regulation engine can invoke this function");
		ERC20(getDai()).transferFrom(sender, self, dai);//failing live at this point
		WeiDai(getWeiDai()).issue(msg.sender, weidai);
	}

	function setClaimDelegate(address delegate, uint rewardPercentage) external versionMatch {
		require(rewardPercentage<=10000, "reward must be % expressed as an integer between 0 and 10,000");
		redeemDelegateReward[msg.sender][delegate] = rewardPercentage + 1;
	}

	function disableClaimDelegate(address delegate) external versionMatch {
		redeemDelegateReward[msg.sender][delegate] = 0;
	}

	function redeemWeiDaiFor(uint weiDai, address recipient, address bankVersion) external {
		require(msg.sender == versionController || redeemDelegateReward[recipient][msg.sender]>0, "delegate for disabled for this user: recipient must invoke the setClaimDelegate function.");
		WeiDaiBank(bankVersion).redeem(weiDai,recipient,msg.sender,redeemDelegateReward[recipient][msg.sender]);
	}

	function redeemWeiDai(uint weiDai) external versionMatch {
		redeem (weiDai, msg.sender,address(0),0);
	}

	function redeem(uint weiDai, address recipient, address delegate, uint reward) public {
		uint exchangeRate = daiPerMyriadWeidai();
		uint fee = WeiDai(getWeiDai()).totalSupply() - weiDai == 0? 0 : weiDai*2/100;
		uint donation = (fee*PatienceRegulationEngine(getPRE()).getDonationSplit(recipient))/100;


		WeiDai(getWeiDai()).burn(recipient, weiDai-donation);
		WeiDai(getWeiDai()).transferFrom(recipient, self,donation);

		uint weiDaiToRedeem = weiDai - fee;

		uint daiPayable = weiDaiToRedeem
		.mul(exchangeRate)
		.div(10000);
		uint delegateDai = 0;
		if(delegate!=address(0) && delegate != versionController)
		{
			delegateDai = reward > 0? (daiPayable * (reward-1))/10000 : 0;
			daiPayable = daiPayable.sub(delegateDai);
			ERC20(getDai()).transfer(delegate, daiPayable);
		}
		ERC20(getDai()).transfer(recipient, daiPayable - delegateDai);
		lastKnownExchangeRate = daiPerMyriadWeidai();
	}

	function withdrawDonations() public onlyPrimary {
		uint balance = ERC20(getWeiDai()).balanceOf(self);
		ERC20(getWeiDai()).transfer(donationAddress,balance);
	} 
}
