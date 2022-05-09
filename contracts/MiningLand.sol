// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "./interface/IAsset1155.sol";
import "./interface/IICO.sol";

contract FarmingPool is Initializable, ReentrancyGuardUpgradeable, OwnableUpgradeable {
    using CountersUpgradeable for CountersUpgradeable.Counter;
    // Declare variables
    IAsset1155 public badgeContract;
    IERC20Upgradeable public tokenA;
    IERC20Upgradeable public tokenB;
    IERC20Upgradeable public busd;
    address public distributor;
    address public refDistributor;
    address public vault;
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
        bool enable;
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
    event AddMiningPool(
        address user,
        uint256 nftAmount,
        uint256 poolId
    );

    event RemoveMiningPool(
        address user,
        uint256 nftAmount,
        uint256 poolId
    );

    event HarvestMiningReward(
        address user,
        uint256 tokenReward,
        uint256 poolId
    );

    event CreateMiningPool(
        uint256 nftId,
        uint256 roi
    );

    event SetFarmingBNBPool(
        uint256 timestamp,
        uint256 rate,
        uint256 decimal,
        uint256 roi
    );

    event AddLiquidityBNBPool(
        address user,
        uint256 tokenAmount,
        uint256 bnbAmount
    );

    event RemoveLiquidityBNBPool(
        address user,
        uint256 tokenAmount,
        uint256 bnbAmount
    );

    event HarvestFarmingBNBPool(
        address user,
        uint256 tokenAAmount
    );

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

    // upgradeable variables and structs
    mapping(address => mapping(uint256 => uint256)) public lastMiningClaim;

    // FUNCTION
    function __FarmingInit(
        address _tokenA,
        address _tokenB,
        address _distributor,
        address _refDistributor,
        address _badgeContract,
        address _icoContract,
        address _busdAddress
    ) public initializer {
        __Ownable_init();
        tokenA = IERC20Upgradeable(_tokenA);
        tokenB = IERC20Upgradeable(_tokenB);
        distributor = _distributor;
        refDistributor = _refDistributor;
        busd = IERC20Upgradeable(_busdAddress);
        badgeContract = IAsset1155(_badgeContract);
        ico = IICO(_icoContract);
        MONTH_IN_SECOND = 30 days;
        delayTime = [5, 10, 15, 20];
    }

    function setMiningInfo(
        address _tokenA,
        address _tokenB,
        address _distributor,
        address _refDistributor,
        address _badgeContract,
        address _icoContract,
        address _busdAddress
    ) external onlyOwner {
        tokenA = IERC20Upgradeable(_tokenA);
        tokenB = IERC20Upgradeable(_tokenB);
        distributor = _distributor;
        refDistributor = _refDistributor;
        busd = IERC20Upgradeable(_busdAddress);
        badgeContract = IAsset1155(_badgeContract);
        ico = IICO(_icoContract);
    }

    // --- NFT Liquidity Pool ---
    // create LP
    function createMiningPool(
        uint256 _nftId,
        uint256 _roi
    ) external onlyOwner {
        poolId.increment();
        uint256 id = poolId.current();
        NFTPool storage nftPool = _NFTPool[id];
        nftPool.NFTId = _nftId;
        nftPool.ROI = _roi;

        emit CreateMiningPool(_nftId, _roi);
    }
    // update LP

    // add LP
    function addMiningPool(
        uint256 _poolId,
        uint256 _ftAmount
    ) public nonReentrant {
        require(_poolId <= poolId.current(), "invalid poolId");

        NFTPool storage nftPool = _NFTPool[_poolId];
        uint256 badgeBalance = badgeContract.balanceOf(msg.sender, nftPool.NFTId);
        tokenB.transferFrom(msg.sender, address(this), _ftAmount);

        // assign balance
        FTUser storage ftUser = _FTUser[msg.sender][_poolId];
        if(!ftUser.enable) {
            require(badgeBalance > 0, "lacking require land");
            badgeContract.safeTransferFrom(msg.sender, address(this), nftPool.NFTId, 1, "");
            ftUser.enable = true;
        }
        ftUser.FTBalance += _ftAmount;
        nftPool.FTBalance += _ftAmount;
        ftUser.lastUpdate = block.timestamp;

        _harvestMiningPoolReward(msg.sender, _poolId);

        emit AddMiningPool(msg.sender, _ftAmount, _poolId);
    }

    // remove LP
    function removeMiningPool(
        uint256 _poolId,
        uint256 _ftAmount
    ) public nonReentrant {
        _harvestMiningPoolReward(msg.sender, _poolId);

        require(
            _poolId <= poolId.current() && _poolId > 0, 
            "invalid poolId"
        );
        NFTPool storage nftPool = _NFTPool[_poolId];
        FTUser storage ftUser = _FTUser[msg.sender][_poolId];
        require(ftUser.FTBalance >= _ftAmount, "not enough token");

        if(ftUser.lastUpdate + 5 * _poolId * 86400 > block.timestamp) {
            tokenB.transfer(msg.sender, _ftAmount / 10);
        } else {
            tokenB.transfer(msg.sender, _ftAmount);
        }

        // assign balance
        ftUser.FTBalance -= _ftAmount;
        nftPool.FTBalance -= _ftAmount;
        ftUser.lastUpdate = block.timestamp;

        if(ftUser.FTBalance == 0 && ftUser.enable == true) {
            badgeContract.safeTransferFrom(address(this), msg.sender, nftPool.NFTId, 1, "");
            ftUser.enable = false;
        }

        emit RemoveMiningPool(msg.sender, _ftAmount, _poolId);
    }

    function estimateMiningPoolReward(address _account, uint256 _poolId) public view returns(uint256) {
        NFTPool memory nftPool = _NFTPool[_poolId];
        FTUser memory ftUser = _FTUser[_account][_poolId];
        uint256 lastTime = lastMiningClaim[_account][_poolId];
        if(lastMiningClaim[_account][_poolId] == 0) {
            return 0;
        }
        uint256 period = block.timestamp - lastTime;
        uint256 reward = ftUser.FTBalance * nftPool.ROI * period / 100 / MONTH_IN_SECOND;
        return reward;
    }

    function estimateRefMiningReward(uint256 _poolId, uint256 _reward) public pure returns(uint256) {
        if (_poolId == 2) {
            return _reward / 100;
        } else if (_poolId == 3) {
            return _reward * 2 / 100;
        } else if (_poolId == 4) {
            return _reward * 3 / 100;
        } else {
            return 0;
        }
    }

    function harvestMiningPoolReward(uint256 _poolId) external nonReentrant {
        _harvestMiningPoolReward(msg.sender, _poolId);
    }

    // --- Farming tokenB and BNB ---
    function setFarmingBNBPool(
        uint256 _rate,
        uint256 _decimal,
        uint256 _roi
    ) external onlyOwner {
        tokenBNBPool.rate = _rate;
        tokenBNBPool.decimal = _decimal;
        tokenBNBPool.ROI = _roi;

        emit SetFarmingBNBPool(block.timestamp, _rate, _decimal, _roi);
    }

    function addFarmingBNBPool(
        uint256 _tokenAmount
    ) external payable nonReentrant {
        // transfer token and BNB
        tokenB.transferFrom(msg.sender, address(this), _tokenAmount);
        uint256 _BNB = _tokenAmount * tokenBNBPool.rate / (10 ** tokenBNBPool.decimal);
        // (bool sent, ) = address(this).call{value: _BNB}("");
        // require(sent, "transfer income bnb failed");
        require(msg.value >= _BNB, "not enough BNB");
        tokenBNBPool.tokenBalance += _tokenAmount;
        tokenBNBPool.bnbBalance += _BNB;
        TokenBNBUser storage tokenUser = _TokenBNBUser[msg.sender];
        tokenUser.tokenBalance += _tokenAmount;
        tokenUser.bnbBalance += _BNB;
        tokenUser.lastUpdate = block.timestamp;

        emit AddLiquidityBNBPool(msg.sender, _tokenAmount, _BNB);
    }

    function removeFarmingBNBPool(
        uint256 _tokenAmount
    ) external payable nonReentrant {
        // transfer token and BNB
        tokenB.transfer(msg.sender, _tokenAmount);
        uint256 _BNB = _tokenAmount * tokenBNBPool.rate / (10 ** tokenBNBPool.decimal);
        (bool sent, ) = msg.sender.call{value: _BNB}("");
        require(sent, "transfer outcome bnb failed");
        tokenBNBPool.tokenBalance -= _tokenAmount;
        tokenBNBPool.bnbBalance -= _BNB;
        TokenBNBUser storage tokenUser = _TokenBNBUser[msg.sender];
        tokenUser.tokenBalance -= _tokenAmount;
        tokenUser.bnbBalance -= _BNB;
        tokenUser.lastUpdate = block.timestamp;

        emit RemoveLiquidityBNBPool(msg.sender, _tokenAmount, _BNB);
    }

    function estimateFarmingBNBPoolReward() public view returns(uint256) {
        TokenBNBUser memory tokenUser = _TokenBNBUser[msg.sender];
        uint256 totalTokenEquivalent = tokenUser.tokenBalance  * tokenBNBPool.rate / (10 ** tokenBNBPool.decimal) + tokenUser.bnbBalance;
        uint256 period = block.timestamp - tokenUser.lastUpdate;
        uint256 reward = totalTokenEquivalent * tokenBNBPool.ROI * period / 100 / MONTH_IN_SECOND;
        return reward;
    }

    function harvestFarmingBNBPoolReward() external payable nonReentrant {
        uint256 reward = estimateFarmingBNBPoolReward();
        TokenBNBUser storage tokenUser = _TokenBNBUser[msg.sender];
        // transfer reward
        tokenA.transfer(msg.sender, reward);
        tokenUser.lastUpdate = block.timestamp;

        emit HarvestFarmingBNBPool(msg.sender, reward);
    }

    // function withdrawBNB(
    //     uint256 _amount
    // ) external payable nonReentrant onlyOwner {
    //     (bool sent, ) = msg.sender.call{value: _amount}("");
    //     require(sent, "transfer outcome bnb failed");
    // }

    function transferAKC(uint256 _amount, address _receiver) external onlyOwner {
        tokenB.transfer(_receiver, _amount);
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
        busd.transferFrom(msg.sender, address(this), _BUSD);
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
        uint256 _BUSD = _tokenAmount * tokenBUSDPool.rate / (10 ** tokenBUSDPool.decimal);
        tokenBUSDPool.tokenBalance -= _tokenAmount;
        tokenBUSDPool.busdBalance -= _BUSD;
        TokenBUSDUser storage tokenUser = _TokenBUSDUser[msg.sender];
        tokenUser.tokenBalance -= _tokenAmount;
        tokenUser.busdBalance -= _BUSD;
        tokenUser.lastUpdate = block.timestamp;
        // transfer token and BNB
        tokenB.transfer(msg.sender, _tokenAmount);
        busd.transferFrom(address(this), msg.sender, _BUSD);

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

        emit HarvestFarmingBNBPool(msg.sender, reward);
    }

    // internal and override functions
    function _harvestMiningPoolReward(address _account, uint256 _poolId) internal {
        uint256 reward = estimateMiningPoolReward(_account, _poolId);
        // transfer reward
        if(reward > 0) {
            tokenB.transfer(_account, reward);
        }
        address referal = ico.getReferal(_account);
        uint256 refReward = estimateRefMiningReward(_poolId, reward);
        if(refReward > 0 && referal != address(0)) {
            tokenB.transfer(referal, refReward);
        }
        lastMiningClaim[_account][_poolId] = block.timestamp;
        emit HarvestMiningReward(_account, reward, _poolId);
    }

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}