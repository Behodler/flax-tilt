// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import {ERC20} from "@oz_tilt/contracts/token/ERC20/ERC20.sol";
import {UniswapV2Router02} from "@uniswap/periphery/UniswapV2Router02.sol";
import {WETH9} from "@uniswap/periphery/test/WETH9.sol";
import {UniswapV2Factory} from "@uniswap/core/UniswapV2Factory.sol";
import {IUniswapV2Factory} from "@uniswap/core/interfaces/IUniswapV2Factory.sol";
import {IUniswapV2Pair} from "@uniswap/core/interfaces/IUniswapV2Pair.sol";
import {Ownable} from "@oz_tilt/contracts/access/Ownable.sol";
import "../src/Errors.sol";
import "@uniswap/periphery/libraries/UniswapV2Library.sol";
import {PyroTokenWrapper} from "../src/UniPriceFetcher.sol";
import "@uniswap/periphery/libraries/UniswapV2Library.sol";

contract MockToken is ERC20 {
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {}

    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }

    function burn(uint256 amount) public {
        _burn(msg.sender, amount);
    }
}

contract PyroToken is PyroTokenWrapper, ERC20 {
    address baseToken;

    constructor(
        address _baseToken,
        string memory name,
        string memory symbol
    ) ERC20(name, symbol) {
        baseToken = _baseToken;
    }

    function config()
        public
        view
        override
        returns (address, address, address, bool)
    {
        return (address(0), baseToken, address(0), false);
    }

    function burn (uint amount) public {
        _burn(msg.sender,amount);
    }

    function mint(uint amount) public {
        uint R = redeemRate();
        uint minted = (amount * (1 ether)) / R;
        ERC20(baseToken).transferFrom(msg.sender, address(this), amount);
        _mint(msg.sender, minted);
    }

    function redeem(uint amount) public {
        uint256 _redeemRate = redeemRate();
        _burn(msg.sender, amount);
        uint256 fee = amount / 50;

        uint256 net = amount - fee;
        uint256 baseTokens = (_redeemRate * net) / (1 ether);

        ERC20(baseToken).transfer(msg.sender, baseTokens);
    }

    function redeemRate() public view override returns (uint) {
        if (totalSupply() == 0) {
            return 1 ether;
        }
        return
            (ERC20(baseToken).balanceOf(address(this)) * (1 ether)) /
            totalSupply();
    }
}
