pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./helpers/TransferHelpers.sol";

contract SentienceToken is ERC20, AccessControl, Ownable {
  using SafeMath for uint256;

  bytes32 public excludedFromTaxRole = keccak256(abi.encodePacked("EXCLUDED_FROM_TAX"));
  bytes32 public retrieverRole = keccak256(abi.encodePacked("RETRIEVER_ROLE"));
  address public taxCollector;
  uint256 public taxPercentage;

  constructor(
    string memory name_,
    string memory symbol_,
    uint256 amount,
    address tCollector,
    uint256 tPercentage
  ) ERC20(name_, symbol_) {
    _grantRole(excludedFromTaxRole, _msgSender());
    _grantRole(retrieverRole, _msgSender());
    _mint(_msgSender(), amount);
    taxCollector = tCollector;
    taxPercentage = tPercentage;
  }

  function _transfer(
    address sender,
    address recipient,
    uint256 amount
  ) internal virtual override(ERC20) {
    if (!hasRole(excludedFromTaxRole, sender) && sender != address(this)) {
      uint256 tax = amount.mul(taxPercentage).div(100);
      super._transfer(sender, taxCollector, tax);
      super._transfer(sender, recipient, amount.sub(tax));
    } else {
      super._transfer(sender, recipient, amount);
    }
  }

  function retrieveEther(address to) external {
    require(hasRole(retrieverRole, _msgSender()), "only_retriever");
    TransferHelpers._safeTransferEther(to, address(this).balance);
  }

  function retrieveERC20(
    address token,
    address to,
    uint256 amount
  ) external {
    require(hasRole(retrieverRole, _msgSender()), "only_retriever");
    TransferHelpers._safeTransferERC20(token, to, amount);
  }

  receive() external payable {}
}
