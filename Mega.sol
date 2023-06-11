// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MyToken is ERC20, ReentrancyGuard, Ownable {
    mapping (address => bool) private _isBlacklisted;
    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;

    uint256 private constant MAX = ~uint256(0);
    uint256 private _tTotal;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;

    uint256 private _maxTxAmount; // max transaction amount to prevent whales
    uint256 public burnRate = 1; // 0.01%

    constructor(uint256 initialSupply, uint256 maxTxAmount) ERC20("MyToken", "MTK") {
        _tTotal = initialSupply;
        _maxTxAmount = maxTxAmount;
        _rOwned[_msgSender()] = _rTotal;

        // Minting the initial supply
        _mint(msg.sender, initialSupply);
    }

    function isBlacklisted(address account) public view returns (bool) {
        return _isBlacklisted[account];
    }

    function blacklistAddress(address account, bool value) external onlyOwner {
        _isBlacklisted[account] = value;
    }

    function transfer(address recipient, uint256 amount) public virtual override nonReentrant returns (bool) {
        require(amount <= _maxTxAmount, "Transfer amount exceeds the maxTxAmount.");
        require(!_isBlacklisted[msg.sender], "You are blacklisted!");

        uint256 burnAmount = calculateBurnAmount(amount);
        uint256 sendAmount = amount - burnAmount;
        
        // Updating reflective balances
        uint256 rAmount = amount * _getRate();
        uint256 rBurn = burnAmount * _getRate();
        uint256 rSend = sendAmount * _getRate();

        _rOwned[msg.sender] -= rAmount;
        _rOwned[recipient] += rSend;
        _rTotal -= rBurn;

        // Burning
        super.transfer(address(0), burnAmount);
        super.transfer(recipient, sendAmount);

        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override nonReentrant returns (bool) {
        require(amount <= _maxTxAmount, "Transfer amount exceeds the maxTxAmount.");
        require(!_isBlacklisted[sender], "Address is blacklisted!");

        uint256 burnAmount = calculateBurnAmount(amount);
        uint256 sendAmount = amount - burnAmount;

        // Updating reflective balances
        uint256 rAmount = amount * _getRate();
        uint256 rBurn = burnAmount * _getRate();
        uint256 rSend = sendAmount * _getRate();

        _rOwned[sender] -= rAmount;
        _rOwned[recipient] += rSend;
        _rTotal -= rBurn;

        // Burning
        super.transferFrom(sender, address(0), burnAmount);
        super.transferFrom(sender, recipient, sendAmount);

        return true;
    }

    function totalFees() public view returns (uint256) {
        return _tFeeTotal;
    }

    function calculateBurnAmount(uint256 amount) public view returns (uint256) {
        return amount * burnRate / 10000; // 0.01% of the amount
    }

    function getMaxTxAmount() public view returns (uint256) {
        return _maxTxAmount;
    }

    function setMaxTxAmount(uint256 maxTxAmount) public onlyOwner {
        _maxTxAmount = maxTxAmount;
    }

    function _getRate() private view returns(uint256) {
        return _rTotal / _tTotal;
    }
}
