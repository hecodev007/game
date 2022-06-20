// SPDX-License-Identifier: MIT

pragma solidity =0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "../libraries/InitializableOwner.sol";
//import "../interfaces/IDsgNft.sol";
import "../libraries/LibPart.sol";
import "../libraries/Random.sol";
import "./CrystalNft.sol";


//library TransferHelper {
//    function safeApprove(address token, address to, uint value) internal {
//        // bytes4(keccak256(bytes('approve(address,uint256)')));
//        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
//        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
//    }
//
//    function safeTransfer(address token, address to, uint value) internal {
//        // bytes4(keccak256(bytes('transfer(address,uint256)')));
//        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
//        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
//    }
//
//    function safeTransferFrom(address token, address from, address to, uint value) internal {
//        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
//        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
//        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
//    }
//
//    function safeTransferETH(address to, uint value) internal {
//        (bool success,) = to.call{value : value}(new bytes(0));
//        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
//    }
//}

contract DsgNft is ERC721, InitializableOwner, ReentrancyGuard, Pausable
{
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;
    EnumerableSet.AddressSet private _minters;
    using Strings for uint256;
    mapping(address => uint256) UserChance;

    event Minted(
        uint256 indexed id,
        address to
    );
    event BatchMinted(
        uint256[] id,
        address to
    );
    event Upgraded(uint256 indexed id0, uint256 indexed id1, uint256 new_id, address user);

    /*
     *     bytes4(keccak256('getRoyalties(uint256)')) == 0xbb3bafd6
     *     bytes4(keccak256('sumRoyalties(uint256)')) == 0x09b94e2a
     *
     *     => 0xbb3bafd6 ^ 0x09b94e2a == 0xb282e1fc
     */
    bytes4 private constant _INTERFACE_ID_GET_ROYALTIES = 0xbb3bafd6;
    bytes4 private constant _INTERFACE_ID_ROYALTIES = 0xb282e1fc;

    uint256 private _tokenId;
    string private _baseURIVar;

    IERC20 private _token;
    IERC20 private _tokenOther;
    CrystalNft private _crystalNft;
    address public _feeWallet;

    string private _name;
    string private _symbol;

    uint256 public price;
    uint256 public price_other;
    // mapping(uint256 => LibPart.NftInfo) private _nfts;
    address public _teamWallet;
    constructor() public ERC721("", "")
    {
        super._initialize();
    }

    function initialize(
        string memory name_,
        string memory symbol_,
        address teamAddress,
        string memory baseURI_
    ) public onlyOwner {
        _tokenId = 1000;

        _registerInterface(_INTERFACE_ID_GET_ROYALTIES);
        _registerInterface(_INTERFACE_ID_ROYALTIES);
        _name = name_;
        _symbol = symbol_;
        _baseURIVar = baseURI_;

    }


    function name() public view override returns (string memory) {
        return _name;
    }

    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    function setBaseURI(string memory uri) public onlyOwner {
        _baseURIVar = uri;
    }

    function baseURI() public view override returns (string memory) {
        return _baseURIVar;
    }

    function setFeeWallet(address feeWallet_) public onlyOwner {
        _feeWallet = feeWallet_;
    }

    function setCrystalNft(address crystalNft_) public onlyOwner {
        _crystalNft = CrystalNft(crystalNft_);
    }

    function setPrice(uint256 price_, uint256 price_other_) public onlyOwner {
        price = price_;
        price_other = price_other_;
    }

    function setFeeToken(address token, address token_other) public onlyOwner {
        _token = IERC20(token);
        _tokenOther = IERC20(token_other);
    }


    function _doMint(
        address to
    ) internal returns (uint256) {
        _tokenId++;


        _mint(to, _tokenId);

        emit Minted(_tokenId, to);
        return _tokenId;
    }

    function batchMint(
        address to, uint256 amount
    ) public payable nonReentrant {
        require(amount >= 5, "low amount");

        //TransferHelper.safeTransferETH(_teamWallet, msg.value);
        if (address(_token) != address(0)) {
            TransferHelper.safeTransferFrom(address(_token), msg.sender, _teamWallet, price.mul(amount));
        }

        if (address(_tokenOther) != address(0)) {
            TransferHelper.safeTransferFrom(address(_tokenOther), msg.sender, _teamWallet, price_other.mul(amount));
        }
        if (getReward(msg.sender) == true) {
            _crystalNft.mint(msg.sender);
        }
        uint256[] memory nftIds = new uint256[](amount);
        for (uint256 i = 0; i < amount; i++) {
            nftIds[i] = _doMint(to);
        }
        emit BatchMinted(nftIds, to);
    }

    function getReward(address user) internal returns (bool){
        uint256 seed = Random.computerSeed() / 23 % 100;
        uint256 chance = UserChance[user];
        if (chance > 0) {
            UserChance[user] = chance + 5;
            if (seed <= chance + 5) {
                UserChance[user] = 0;
                return true;
            } else {
                return false;
            }

        } else {
            UserChance[user] = 5;
            if (seed <= 1) {
                UserChance[user] = 0;
                return true;
            } else {
                return false;
            }

        }

    }

    function mint(
        address to
    ) public payable nonReentrant returns (uint256 tokenId){
        //  require(msg.value >= price, "low price");

        //TransferHelper.safeTransferETH(_teamWallet, msg.value);
        if (address(_token) != address(0)) {
            TransferHelper.safeTransferFrom(address(_token), msg.sender, _teamWallet, price);
        }

        if (address(_tokenOther) != address(0)) {
            TransferHelper.safeTransferFrom(address(_tokenOther), msg.sender, _teamWallet, price_other);
        }
        tokenId = _doMint(to);
    }
    //    function getPower(uint256 tokenId) public view  returns (uint256) {
    //        return _nfts[tokenId].power;
    //    }
    //
    //    function getLevel(uint256 tokenId) public view  returns (uint256) {
    //        return _nfts[tokenId].level;
    //    }
    function upgradeNft(uint256 nftId1, uint256 nftId2) public nonReentrant whenNotPaused
    {
        burn_inter(nftId1);
        burn_inter(nftId2);

        uint256 tokenId = _doMint(msg.sender);

        emit Upgraded(nftId1, nftId2, tokenId, msg.sender);
    }

    function getCurId() public view returns (uint256){
        return _tokenId;
    }

    function burn(uint256 tokenId) public {
        address owner = ERC721.ownerOf(tokenId);
        require(_msgSender() == owner, "caller is not the token owner");

        _burn(tokenId);
    }

    function burn_inter(uint256 tokenId) internal {
        address owner = ERC721.ownerOf(tokenId);
        require(_msgSender() == owner, "caller is not the token owner");

        _burn(tokenId);
    }
}
