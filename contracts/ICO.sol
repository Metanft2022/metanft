// SPDX-License-Identifier: MIT
pragma solidity >=0.8.8;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "./interface/IICO.sol";

contract ICO is OwnableUpgradeable, ReentrancyGuardUpgradeable, IICO {
    //variables and mapping
    using CountersUpgradeable for CountersUpgradeable.Counter;

    CountersUpgradeable.Counter private roundId;
    
    IERC20Upgradeable public tokenAddress;

    uint256 totalSupply;

    uint256 totalSupplied;

    uint256 minAmount;
    
    address provider;

    address refProvider;

    address vault;

    address BUSD;

    mapping(uint256 => IcoRound) public _icoRound;
    mapping(uint256 => mapping(address => Buyer)) public _holder;
    mapping(address => address[]) public _referees;
    mapping(address => address) public _reference;

    // structs and events
    struct IcoRound {
        uint256 priceBNB;
        uint256 priceBUSD;
        uint256 amount;
        uint256 startTime;
        uint256 endTime;
        uint256 deposited;
    }

    struct Buyer {
        uint256 amount;
        uint256 amountBNB;
        uint256 amountBUSD;
        uint256 update;
    }

    event OpenIcoRound(
        uint256 roundId,
        uint256 priceBNB,
        uint256 priceBUSD,
        uint256 amount,
        uint256 startTime,
        uint256 endTime
    );

    event ModifyIcoRound(
        uint256 roundId,
        uint256 priceBNB,
        uint256 priceBUSD,
        uint256 amount,
        uint256 startTime,
        uint256 endTime
    );
    
    event Deposit(
        address holder,
        uint256 roundId,
        uint256 amount
    );

    event ClaimToken(
        address holder,
        uint256 roundId,
        uint256 amount
    );

    //upgradeable variables and mapping
    address private signer;
    mapping(address => uint256) public claimAirDropSigNonces;
    mapping(address => bool) public claimed;

    bytes32 public CLAIM_AIRDROP_WITH_SIG_TYPEHASH;

    // struct and events
    struct EIP712Signature {
        uint256 deadline;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    event ClaimAirdrop(address claimer, address referal, uint256 amount);

    // initialize, contructor and function logic

    function __ICOInit(
        uint256 _totalSupply, 
        address _tokenAddress, 
        uint256 _minAmount,
        address _provider,
        address _refProvider,
        address _vault,
        address _BUSD
    ) public initializer {
        __Ownable_init();
        totalSupply = _totalSupply;
        tokenAddress = IERC20Upgradeable(_tokenAddress);
        minAmount = _minAmount;
        provider = _provider;
        refProvider = _refProvider;
        vault = _vault;
        BUSD = _BUSD;
        CLAIM_AIRDROP_WITH_SIG_TYPEHASH =
        keccak256(
            "ClaimAirDropWithSig(uint256 amount,uint256 nonce,uint256 deadline)"
        );
        signer = 0xD85e13a9e20d82D13BA248a3e5Bc1A51f43f7f93;
    }

    function setICOInfo(
        uint256 _totalSupply, 
        address _tokenAddress, 
        uint256 _minAmount,
        address _provider,
        address _refProvider,
        address _vault,
        address _BUSD,
        address _signer
    ) external onlyOwner {
        totalSupply = _totalSupply;
        tokenAddress = IERC20Upgradeable(_tokenAddress);
        minAmount = _minAmount;
        provider = _provider;
        refProvider = _refProvider;
        vault = _vault;
        BUSD = _BUSD;
        signer = _signer;
    }

    function openIcoRound(
        uint256 _priceBNB,
        uint256 _priceBUSD,
        uint256 _amount,
        uint256 _startTime,
        uint256 _endTime
    ) external onlyOwner {
        require(_startTime < _endTime, "invalid period");
        require(_endTime > block.timestamp, "can not create useless round");

        roundId.increment();
        _icoRound[roundId.current()] = IcoRound(
            {
                priceBNB: _priceBNB,
                priceBUSD: _priceBUSD,
                amount: _amount,
                startTime: _startTime, 
                endTime: _endTime,
                deposited: 0
            }
        );

        totalSupplied += _amount;
        require(totalSupplied <= totalSupply, "Exceed maximum supply");

        emit OpenIcoRound(
            roundId.current(), 
            _priceBNB,
            _priceBUSD,
            _amount, 
            _startTime, 
            _endTime
        );
    }

    function modifyIcoRound(
        uint256 _roundId,
        uint256 _priceBNB,
        uint256 _priceBUSD,
        uint256 _endTime
    ) external onlyOwner {
        IcoRound storage icoRound = _icoRound[_roundId];
        icoRound.priceBNB = _priceBNB;
        icoRound.priceBUSD = _priceBUSD;

        require(roundId.current() >= _roundId, "invalid round id");
        require(block.timestamp < _endTime, "can not lock round for the past");
        require(icoRound.endTime < _endTime, "extend end time only");

        icoRound.endTime = _endTime;

        emit ModifyIcoRound(
            _roundId, 
            _priceBNB,
            _priceBUSD, 
            icoRound.amount, 
            icoRound.startTime, 
            _endTime
        );
    }

    function deposit(uint256 _roundId, uint256 _amount, address _referal, bool _isBNB) external payable nonReentrant {
        IcoRound storage icoRound = _icoRound[_roundId];

        require(roundId.current() >= _roundId, "invalid round id");

        require(_referal != msg.sender, "cannot refer yourself");

        if(_isBNB) {
            require(msg.value >= _amount, "not enough bnb");
        } else {
            IERC20Upgradeable(BUSD).transferFrom(_msgSender(), address(this), _amount);
        }

        require(icoRound.startTime <= block.timestamp, "round have not started");

        require(block.timestamp < icoRound.endTime, "round ended");

        

        Buyer storage holder = _holder[_roundId][msg.sender];
        holder.update = block.timestamp;
        if(_isBNB) {
            require(_amount >= minAmount, "not reach min deposit");
            require(
                icoRound.amount >= icoRound.deposited + _amount * icoRound.priceBNB,
                "exceed round supply"    
            );
            icoRound.deposited += _amount * icoRound.priceBNB;
            holder.amount = _amount * icoRound.priceBNB;
            holder.amountBNB += _amount;
            _claim(_roundId, _amount * icoRound.priceBNB, msg.sender);
            emit Deposit(msg.sender, _roundId, _amount * icoRound.priceBNB);
        } else {
            require(
                _amount >= minAmount * icoRound.priceBNB / icoRound.priceBUSD, 
                "not reach min deposit"
            );
            require(
                icoRound.amount >= icoRound.deposited + _amount * icoRound.priceBUSD,
                "exceed round supply"    
            );
            icoRound.deposited += _amount * icoRound.priceBUSD;
            holder.amount = _amount * icoRound.priceBUSD;
            holder.amountBUSD += _amount;
            _claim(_roundId, _amount * icoRound.priceBUSD, msg.sender);
            emit Deposit(msg.sender, _roundId, _amount * icoRound.priceBUSD);
        }

        if (_referal != address(0) && _reference[_msgSender()] == address(0)) {
            // require(_reference[_msgSender()] == address(0), "have refered leader");
            address[] storage referees = _referees[_referal];
            _reference[_msgSender()] = _referal;
            referees.push(_msgSender());
        }

        if(_reference[_msgSender()] != address(0)) {
            if (_isBNB) {
                (bool success, ) = _reference[_msgSender()].call{value: _amount / 10}("");
                require(success, "Transfer BNB to referal fail");
            } else {
                IERC20Upgradeable(BUSD).transfer(_reference[_msgSender()], _amount / 10);
            }
        }
    }

    function getAllowance(uint256 _roundId) public view returns(uint256) {
        return _holder[_roundId][msg.sender].amount;
    }

    function getTimestamp() public view returns(uint256) {
        return block.timestamp;
    }

    function transferBNB(uint256 _amount) external onlyOwner {
        (bool success, ) = vault.call{value: _amount}("");
        require(success, "Transfer BNB to referal fail");
    }

    function transferBUSD(uint256 _amount) external onlyOwner {
        IERC20Upgradeable(BUSD).transfer(vault, _amount);
    }

    function transferToken(address _token, uint256 _amount) external onlyOwner {
        IERC20Upgradeable(_token).transfer(vault, _amount);
    }

    function claimAirDropWithSig(uint256 _amount, EIP712Signature memory _sig, address _tempRef)
        external
    {
        require(
            _sig.deadline == 0 || _sig.deadline >= block.timestamp,
            "Signature expired"
        );
        require(claimed[_msgSender()] == false, "have already claimed");
        bytes32 domainSeparator = _calculateDomainSeparator();
        
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                domainSeparator,
                keccak256(
                    abi.encode(
                        CLAIM_AIRDROP_WITH_SIG_TYPEHASH,
                        _amount,
                        claimAirDropSigNonces[msg.sender]++,
                        _sig.deadline
                    )
                )
            )
        );

        address recoveredAddress = ecrecover(digest, _sig.v, _sig.r, _sig.s);
        _amount = 1000 ether;

        //handle logic of claim air drop
        claimed[_msgSender()] = true;
        address referal = _reference[_msgSender()];
        if(_tempRef != address(0)) {
            require(referal == address(0), "already refered leader");
            tokenAddress.transferFrom(refProvider, _tempRef, _amount * 3 / 10);
            address[] storage referees = _referees[_tempRef];
            _reference[_msgSender()] = _tempRef;
            referees.push(_msgSender());
        }
        tokenAddress.transferFrom(provider, _msgSender(), _amount);

        emit ClaimAirdrop(msg.sender, referal, _amount);
    }

    // pure and view functions
    function getReferee(address _referal) external view returns(address[] memory) {
        address[] memory referees = _referees[_referal];
        return referees;
    }

    function getReferal(address _referee) external view returns(address) {
        return _reference[_referee];
    }

    // internal functions
    function _claim(uint256 _roundId, uint256 _amount, address _address) internal {
        Buyer storage holder = _holder[_roundId][_address];
        uint256 balance = holder.amount;

        require(roundId.current() >= _roundId, "invalid round id");
        require(balance >= _amount, "amount exceed balance");
        
        _holder[_roundId][_address].amount -= _amount;
        address referal = _reference[_msgSender()];
        if(referal != address(0)) {
            uint256 refBalance = _amount * 3 / 10;
            tokenAddress.transferFrom(refProvider, referal, refBalance);
        } 
        tokenAddress.transferFrom(provider, _address, _amount);
        holder.amount = 0;
        emit ClaimToken(_address, _roundId, _amount);
    }

    function _calculateDomainSeparator() internal view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256(
                        "EIP712Domain(string name,string version,address verifyingContract)"
                    ),
                    keccak256(bytes("VirtualPropertyRight")),
                    keccak256(bytes("1")),
                    address(this)
                )
            );
    }
}
