// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;
import {Ownable} from "@oz_tilt/contracts/access/Ownable.sol";
import "./ITilter.sol";
import "./Tilter.sol";
import "@uniswap/periphery/interfaces/IUniswapV2Router02.sol";
import "./Errors.sol";

//Note: in order to reassociate a ref token with a new tilter,
//first eject and then deploy or adopt
contract TilterFactory is Ownable {
    IUniswapV2Router02 router;
    address public flax;
    address public oracle;
    address issuer;
    address weth;

    //refToken -> tilter mapping
    mapping(address => address) public tiltersByRef;
    //two way mapping
    mapping(address => address) public refByTilter;

    constructor(
        address uniRouter,
        address _flax,
        address _oracle,
        address _issuer
    ) Ownable(msg.sender) {
        router = IUniswapV2Router02(uniRouter);
        flax = _flax;
        oracle = _oracle;
        issuer = _issuer;
        weth = router.WETH();
    }

    function setOracle(address _oracle) public onlyOwner {
        oracle = _oracle;
    }

    function setIssuer(address _issuer) public onlyOwner {
        issuer = _issuer;
    }

    function setEnabled(address tilter, bool enabled) public onlyOwner {
        ITilter(tilter).setEnabled(enabled);
    }

    function configure(
        address tilter,
        address _flx,
        address _oracle,
        address _issuer
    ) public onlyOwner {
        address refToken = refByTilter[tilter];
        if (refToken == address(0)) {
            revert TilterNotMapped(tilter);
        }
        ITilter(tilter).configure(refToken, _flx, _oracle, _issuer);
    }

    function deploy(address refToken) public onlyOwner {
        address existingTilter = tiltersByRef[refToken];
        if (existingTilter != address(0)) {
            revert RefTokenTaken(refToken, existingTilter);
        }
        Tilter t = new Tilter(flax, address(router));
        t.configure(refToken, flax, oracle, issuer);
        tiltersByRef[refToken] = address(t);
        refByTilter[address(t)] = refToken;
    }

    function getEthTilter() public view returns (address tilter) {
        return tiltersByRef[weth];
    }

    function adoptOrphanTilter(address tilter) public onlyOwner {
        (address ref_token, , , , , ) = Tilter(tilter).VARS();
        address existingTilter = tiltersByRef[ref_token];

        if (existingTilter != address(0) && tilter != existingTilter) {
            if (Ownable(tilter).owner() == address(this)) {
                //don't revert if this was a mistake
                Ownable(tilter).transferOwnership(msg.sender);
                return;
            } else {
                revert RefTokenTaken(ref_token, existingTilter);
            }
        }
        if (Ownable(tilter).owner() != address(this)) {
            revert AdoptionRequiresOwnershipTransfer(Ownable(tilter).owner());
        }

        tiltersByRef[ref_token] = tilter;
        refByTilter[tilter] = ref_token;
    }

    function abandonTilter(address tilter) public onlyOwner {
        Ownable(tilter).transferOwnership(msg.sender);
        (address ref_token, , , , , ) = Tilter(tilter).VARS();
        tiltersByRef[ref_token] = address(0);
        refByTilter[tilter] = address(0);
    }
}
