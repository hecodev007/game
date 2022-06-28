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

contract NftRewardPool is Ownable, IERC721Receiver, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableSet for EnumerableSet.AddressSet;

    struct UserInfo {
        EnumerableSet.UintSet nfts;
        uint256 nftAmount;
        uint256 harvestTime;
    }


    uint constant MAX_LEVEL = 6;


    IERC20 public rewardToken;

    uint256 public rewardTokenPerShare;
    uint256 public totalNft;
    IDsgNft public dsgNft; // Address of NFT token contract.

    uint256 public constant BONUS_MULTIPLIER = 1;

    mapping(address => UserInfo) private userInfo;

    uint256 public startTime;


    event Stake(address indexed user, uint256 tokenId);
    // event StakeWithSlot(address indexed user, uint slot, uint256[] tokenIds);
    event Withdraw(address indexed user, uint256 tokenId);
    event EmergencyWithdraw(address indexed user, uint256 tokenId);
    //    event WithdrawSlot(address indexed user, uint slot);
    //    event EmergencyWithdrawSlot(address indexed user, uint slot);

    constructor(
        address _rewardToken,
        address _nftAddress

    ) public {
        dsgNft = IDsgNft(_nftAddress);
        rewardToken = IERC20(_rewardToken);
        // startBlock = _startBlock;
        // lastRewardBlock = _startBlock;
    }




    // View function to see pending STARs on frontend.
    function pendingToken(address _user) external view returns (uint256) {
        UserInfo storage user = userInfo[_user];
        if (user.harvestTime < startTime) {
            return rewardTokenPerShare.mul(user.nftAmount);
        }
        return 0;
    }


    function updatePool() public {
        uint256 curTime = block.timestamp;
        if (startTime == 0) {
            startTime = curTime;
        } else {
            if (curTime.sub(startTime) > 7 days) {
                startTime = startTime.add(7 days);
                //  totalNft
                uint256 bal = rewardToken.balanceOf(address(this));
                rewardTokenPerShare = bal.div(totalNft);
            }
        }
    }

    function getUserInfo(address _user) public view
    returns (
        uint256 numNfts
    )
    {
        UserInfo storage user = userInfo[_user];
        numNfts = user.nfts.length();
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
        uint256 pending = rewardTokenPerShare.mul(user.nftAmount);
        if (user.harvestTime < startTime) {
            safeTokenTransfer(msg.sender, pending);
            user.harvestTime = startTime;
        }


    }

    function withdraw(uint256 _tokenId) public {
        UserInfo storage user = userInfo[msg.sender];
        require(
            user.nfts.contains(_tokenId),
            "withdraw: not token onwer"
        );

        user.nfts.remove(_tokenId);
        harvest();
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

    function stake(uint256 tokenId) public {
        UserInfo storage user = userInfo[msg.sender];

        //updatePool();
        harvest();
        user.nfts.add(tokenId);
        user.nftAmount = user.nftAmount.add(1);
        dsgNft.safeTransferFrom(
            address(msg.sender),
            address(this),
            tokenId
        );
        emit Stake(msg.sender, tokenId);
    }
    function stake_internal(uint256 tokenId) internal {
        UserInfo storage user = userInfo[msg.sender];
        user.nfts.add(tokenId);
        user.nftAmount = user.nftAmount.add(1);
        dsgNft.safeTransferFrom(
            address(msg.sender),
            address(this),
            tokenId
        );
       // emit Stake(msg.sender, tokenId);
    }
    function batchStake(uint256[] memory tokenIds) public {
        harvest();
        for (uint i = 0; i < tokenIds.length; i++) {
            stake_internal(tokenIds[i]);
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


    receive() external payable {
        // assert(msg.sender == WOKT);
        // only accept OKT via fallback from the WOKT contract
    }
}
