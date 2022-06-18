// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/EnumerableSet.sol";
import "../interfaces/IDsgNft.sol";

contract NftEarnErc20Pool is Ownable, IERC721Receiver, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableSet for EnumerableSet.AddressSet;

    struct UserInfo {
        uint256 share; // How many powers the user has provided.
        uint256 rewardDebt; // Reward debt.
        EnumerableSet.UintSet nfts;
        //        uint slots; //Number of enabled card slots
        //        mapping(uint => uint256[]) slotNfts; //slotIndex:tokenIds
        uint256 accRewardAmount;
    }



    struct PoolView {
        address rewardToken;
       // uint8 rewardDecimals;
        uint256 lastRewardBlock;
        uint256 rewardsPerBlock;
        uint256 accRewardPerShare;
        uint256 allocRewardAmount;
        uint256 accRewardAmount;
        uint256 totalAmount;
        address nft;
        string nftSymbol;
    }

    uint constant MAX_LEVEL = 6;


    IERC20 public rewardToken;

    uint256 public rewardTokenPerBlock;

    IDsgNft public dsgNft; // Address of NFT token contract.

    uint256 public constant BONUS_MULTIPLIER = 1;

    mapping(address => UserInfo) private userInfo;
    EnumerableSet.AddressSet private _callers;

    uint256 public startBlock;
    uint256 public endBlock;

    uint256 lastRewardBlock; //Last block number that TOKENs distribution occurs.
    uint256 accRewardTokenPerShare; // Accumulated TOKENs per share, times 1e12. See below.
    uint256 accShare;
    uint256 public allocRewardAmount; //Total number of rewards to be claimed
    uint256 public accRewardAmount; //Total number of rewards


    uint256 public slotAdditionRate = 40000; //400%
    uint256 public enableSlotFee = 10000e18; //10000dsg

    event Stake(address indexed user, uint256 tokenId);
    event StakeWithSlot(address indexed user, uint slot, uint256[] tokenIds);
    event Withdraw(address indexed user, uint256 tokenId);
    event EmergencyWithdraw(address indexed user, uint256 tokenId);
//    event WithdrawSlot(address indexed user, uint slot);
//    event EmergencyWithdrawSlot(address indexed user, uint slot);

    constructor(
        address _rewardToken,
        address _nftAddress,
        uint256 _startBlock
    ) public {
        dsgNft = IDsgNft(_nftAddress);
        rewardToken = IERC20(_rewardToken);
        startBlock = _startBlock;
        lastRewardBlock = _startBlock;
    }

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to)
    public
    pure
    returns (uint256)
    {
        return _to.sub(_from);
    }


    // View function to see pending STARs on frontend.
    function pendingToken(address _user) external view returns (uint256) {
        UserInfo storage user = userInfo[_user];
        uint256 accTokenPerShare = accRewardTokenPerShare;
        uint256 blk = block.number;
        if (blk > endBlock) {
            blk = endBlock;
        }
        if (blk > lastRewardBlock && accShare != 0) {
            uint256 multiplier = getMultiplier(lastRewardBlock, blk);
            uint256 tokenReward = multiplier.mul(rewardTokenPerBlock);
            accTokenPerShare = accTokenPerShare.add(
                tokenReward.mul(1e12).div(accShare)
            );
        }
        return user.share.mul(accTokenPerShare).div(1e12).sub(user.rewardDebt);
    }

    function getPoolInfo() public view
    returns (
        uint256 accShare_,
        uint256 accRewardTokenPerShare_,
        uint256 rewardTokenPerBlock_
    )
    {
        accShare_ = accShare;
        accRewardTokenPerShare_ = accRewardTokenPerShare;
        rewardTokenPerBlock_ = rewardTokenPerBlock;
    }

    function getPoolView() public view returns (PoolView memory) {
        return PoolView({
        rewardToken : address(rewardToken),
      //  rewardDecimals : IERC20Metadata(address(rewardToken)).decimals(),
        lastRewardBlock : lastRewardBlock,
        rewardsPerBlock : rewardTokenPerBlock,
        accRewardPerShare : accRewardTokenPerShare,
        allocRewardAmount : allocRewardAmount,
        accRewardAmount : accRewardAmount,
        totalAmount : dsgNft.balanceOf(address(this)),
        nft : address(dsgNft),
        nftSymbol : IERC721Metadata(address(dsgNft)).symbol()
        });
    }

    function updatePool() public {
        if (block.number < startBlock) {
            return;
        }

        uint256 blk = block.number;
        if (blk > endBlock) {
            blk = endBlock;
        }

        if (blk <= lastRewardBlock) {
            return;
        }

        if (accShare == 0) {
            lastRewardBlock = blk;
            return;
        }
        uint256 multiplier = getMultiplier(lastRewardBlock, blk);
        uint256 rewardTokenReward = multiplier.mul(rewardTokenPerBlock);
        accRewardTokenPerShare = accRewardTokenPerShare.add(
            rewardTokenReward.mul(1e12).div(accShare)
        );
        allocRewardAmount = allocRewardAmount.add(rewardTokenReward);
        accRewardAmount = accRewardAmount.add(rewardTokenReward);

        lastRewardBlock = blk;
    }

    function getUserInfo(address _user) public view
    returns (
        uint256 share,
        uint256 numNfts,
        uint256 rewardDebt
    )
    {
        UserInfo storage user = userInfo[_user];
        share = user.share;
        numNfts = user.nfts.length();
        rewardDebt = user.rewardDebt;
    }

    function getFullUserInfo(address _user) public view
    returns (
        uint256 share,
        uint256[] memory nfts,
        uint256 accRewardAmount_,
        uint256 rewardDebt
    )
    {
        UserInfo storage user = userInfo[_user];
        share = user.share;
        nfts = getNfts(_user);
        rewardDebt = user.rewardDebt;
        accRewardAmount_ = user.accRewardAmount;
    }

    function getNfts(address _user) public view returns (uint256[] memory ids) {
        UserInfo storage user = userInfo[_user];
        uint256 len = user.nfts.length();

        uint256[] memory ret = new uint256[](len);
        for (uint256 i = 0; i < len; i++) {
            ret[i] = user.nfts.at(i);
        }
        return ret;
    }


    function harvest() public {
        updatePool();

        UserInfo storage user = userInfo[msg.sender];

        uint256 pending =
        user.share.mul(accRewardTokenPerShare).div(1e12).sub(
            user.rewardDebt
        );
        safeTokenTransfer(msg.sender, pending);

        allocRewardAmount = pending < allocRewardAmount ? allocRewardAmount.sub(pending) : 0;
        user.accRewardAmount = user.accRewardAmount.add(pending);
        user.rewardDebt = user.share.mul(accRewardTokenPerShare).div(1e12);
    }

    function withdraw(uint256 _tokenId) public {
        UserInfo storage user = userInfo[msg.sender];
        require(
            user.nfts.contains(_tokenId),
            "withdraw: not token onwer"
        );

        user.nfts.remove(_tokenId);

        harvest();

        uint256 power = getNftPower(_tokenId);
        accShare = accShare.sub(power);
        user.share = user.share.sub(power);
        user.rewardDebt = user.share.mul(accRewardTokenPerShare).div(1e12);
        dsgNft.transferFrom(address(this), address(msg.sender), _tokenId);
        emit Withdraw(msg.sender, _tokenId);
    }

    function withdrawAll() public {
        uint256[] memory ids = getNfts(msg.sender);
        for (uint i = 0; i < ids.length; i++) {
            withdraw(ids[i]);
        }
    }

    function emergencyWithdraw(uint256 _tokenId) public {
        UserInfo storage user = userInfo[msg.sender];
        require(
            user.nfts.contains(_tokenId),
            "withdraw: not token onwer"
        );

        user.nfts.remove(_tokenId);

        dsgNft.transferFrom(address(this), address(msg.sender), _tokenId);
        emit EmergencyWithdraw(msg.sender, _tokenId);

        if (user.share <= accShare) {
            accShare = accShare.sub(user.share);
        } else {
            accShare = 0;
        }
        user.share = 0;
        user.rewardDebt = 0;
    }


    function safeTokenTransfer(address _to, uint256 _amount) internal {
        uint256 tokenBal = rewardToken.balanceOf(address(this));
        if (_amount > tokenBal) {
            if (tokenBal > 0) {
                _amount = tokenBal;
            }
        }
        if (_amount > 0) {
                rewardToken.transfer(_to, _amount);
        }
    }

//    function getNftPower(uint256 nftId) public view returns (uint256) {
//        uint256 power = dsgNft.getPower(nftId);
//        return power;
//    }

    function stake(uint256 tokenId,uint256 memory power) public {
        UserInfo storage user = userInfo[msg.sender];

        updatePool();

        user.nfts.add(tokenId);

        dsgNft.safeTransferFrom(
            address(msg.sender),
            address(this),
            tokenId
        );

        if (user.share > 0) {
            harvest();
        }

        //uint256 power = power;
        user.share = user.share.add(power);
        user.rewardDebt = user.share.mul(accRewardTokenPerShare).div(1e12);
        accShare = accShare.add(power);
        emit Stake(msg.sender, tokenId);
    }

    function batchStake(uint256[] memory tokenIds,uint256[] memory powers) public {
        for (uint i = 0; i < tokenIds.length; i++) {
            stake(tokenIds[i],powers[i]);
        }
    }


    function onERC721Received(
        address operator,
        address, //from
        uint256, //tokenId
        bytes calldata //data
    ) public override nonReentrant returns (bytes4) {
        require(
            operator == address(this),
            "received Nft from unauthenticated contract"
        );

        return
        bytes4(
            keccak256("onERC721Received(address,address,uint256,bytes)")
        );
    }

    function addCaller(address _newCaller) public onlyOwner returns (bool) {
        require(_newCaller != address(0), "NftEarnErc20Pool: address is zero");
        return EnumerableSet.add(_callers, _newCaller);
    }

    function delCaller(address _delCaller) public onlyOwner returns (bool) {
        require(_delCaller != address(0), "NftEarnErc20Pool: address is zero");
        return EnumerableSet.remove(_callers, _delCaller);
    }

    function getCallerLength() public view returns (uint256) {
        return EnumerableSet.length(_callers);
    }

    function isCaller(address _caller) public view returns (bool) {
        return EnumerableSet.contains(_callers, _caller);
    }

    function getCaller(uint256 _index) public view returns (address) {
        require(_index <= getCallerLength() - 1, "NftEarnErc20Pool: index out of bounds");
        return EnumerableSet.at(_callers, _index);
    }

    modifier onlyCaller() {
        require(isCaller(msg.sender), "NftEarnErc20Pool: not the caller");
        _;
    }

    receive() external payable {
       // assert(msg.sender == WOKT);
        // only accept OKT via fallback from the WOKT contract
    }
}
