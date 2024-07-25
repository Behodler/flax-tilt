// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import {Coupon} from "@behodler/flax/Coupon.sol";
import {UniswapV2Router02} from "@uniswap/periphery/UniswapV2Router02.sol";
import {WETH9} from "@uniswap/periphery/test/WETH9.sol";
import {UniswapV2Factory} from "@uniswap/core/UniswapV2Factory.sol";
import {IUniswapV2Factory} from "@uniswap/core/interfaces/IUniswapV2Factory.sol";
import {IUniswapV2Pair} from "@uniswap/core/interfaces/IUniswapV2Pair.sol";
import {Oracle} from "src/Oracle.sol";
import {Tilter} from "src/Tilter.sol";
import {IERC20} from "@oz_tilt/contracts/token/ERC20/IERC20.sol";

error insufficientAllowance(uint expected, uint actual);

//price assumption: 1 eth = 50k flx
contract DeployContracts is Script {
    UniswapV2Router02 router;


    function factory() internal view returns (IUniswapV2Factory) {
        return IUniswapV2Factory(router.factory());
    }

    function WETH() internal view returns (WETH9) {
        return WETH9(router.WETH());
    }

    function run() public {
            address owner = msg.sender;
        require(block.chainid == 31337, "unsafe for live chains");

        AddressToString addressToString = new AddressToString();
        DeployMulticall2 multi = new DeployMulticall2();
        vm.startBroadcast();

        // Deploy Coupon
        Coupon flax = new Coupon("Flax", "FLX");
        flax.setMinter(msg.sender, true);
        //mint flx to prepolute eth pair

        //setup pair
        router = new UniswapV2Router02(
            address(new UniswapV2Factory(owner)),
            address(new WETH9())
        );

        factory().createPair(address(flax), address(WETH()));
        address flx_weth_address = factory().getPair(
            address(flax),
            address(WETH())
        );
        IUniswapV2Pair flax_weth = IUniswapV2Pair(flx_weth_address);
        require(owner.balance > 2 ether, "ensure enough eth");
        WETH().deposit{value: 1 ether}();
        WETH().transfer(flx_weth_address, 1 ether);
        flax.mint(5e22, flx_weth_address);
        flax_weth.mint(owner);

        require(flax_weth.totalSupply() > 0, "mint failed");
        require(
            flax.balanceOf(flx_weth_address) == 50_000 ether,
            "mint failed"
        );
        require(WETH().balanceOf(flx_weth_address) == 1 ether, "mint failed");

        //trade a bit
        uint wethOut = router.getAmountOut(100 ether, 50_000 ether, 1 ether);
        require(wethOut == 1990031876438381, "estimation fail");

        flax.mint(100 ether, owner);
        address[] memory path = new address[](2);
        path[0] = address(flax);
        path[1] = address(WETH());

        flax.approve(address(router), 100000000 ether);
        uint allowance = flax.allowance(owner, address(router));
        require(allowance > 1000 ether, "owner has zero allowance");

        router.swapExactTokensForETH(
            100 ether,
            1990031876438381,
            path,
            owner,
            type(uint128).max
        );
        //DELETE: passing up to this point, ERC20 approval failure somewhere below
        
        /*
        //deploy oracle and update
        Oracle oracle = new Oracle(address(factory()));
        oracle.RegisterPair(flx_weth_address, 1);
        vm.roll(block.number + 1);
        vm.warp(block.timestamp + 1 hours + 1);
        oracle.update(address(flax), address(WETH()));
        //trade a bit
        uint newReserveFlax = flax.balanceOf(flx_weth_address);
        uint newReserveWeth = WETH().balanceOf(flx_weth_address);

        wethOut = router.getAmountOut(30 ether, newReserveFlax, newReserveWeth);
        router.swapExactTokensForETH(
            30 ether,
            wethOut,
            path,
            owner,
            type(uint128).max
        );
        //update again.

        vm.warp(block.timestamp + 1 hours + 1);
        oracle.update(address(flax), address(WETH()));

        //Deploy hedgey and Tilter
        TokenLockupPlans hedgey = new TokenLockupPlans("MrHedgey", "HEDGE");
        HedgeyAdapter hedgeyAdapter = new HedgeyAdapter(
            address(flax),
            address(hedgey)
        );
        Tilter priceTilter = new Tilter(address(flax));

        IERC20(address(flax)).approve(address(priceTilter), type(uint).max);

        priceTilter.configure(
            address(WETH()),
            address(flax),
            address(oracle),
            address(hedgeyAdapter)
        );

        //ensure no smelly code introduced behind the scene state changes
        uint initialFlax = priceTilter.safeFlaxBalance();
        vm.assertEq(initialFlax, 0);

        //mint some initial flax for tilting: 5000 eth worth at initial price
        flax.mint(5000e22, owner);
        IERC20(address(flax)).approve(address(priceTilter), type(uint).max);
        priceTilter.transferFlaxIn(5000e22);

        //transfer ownership to 0x70997970C51812dc3A010C7d01b50e0d17dc79C8

        priceTilter.transferOwnership(
            msg.sender
        );

        vm.stopBroadcast();

        address multicall2Address = multi.run();

        string[7] memory contractNames = [
            "Tilter",
            "Oracle",
            "ReferencePair",
            "Coupon",
            "TokenLockupPlan",
            "HedgeyAdapter",
            "Multicall"
        ];
        address[7] memory contractAddresses = [
            address(priceTilter),
            address(oracle),
            flx_weth_address,
            address(flax),
            address(hedgey),
            address(hedgeyAdapter),
            multicall2Address
        ];

        require(
            contractNames.length == contractAddresses.length,
            "misspecified output arrays"
        );
        string memory jsonOutput = "{";
        for (uint i = 0; i < contractAddresses.length; i++) {
            string memory addressString = addressToString.toAsciiString(
                contractAddresses[i]
            );
            string memory jsonPair = getJsonPair(
                contractNames[i],
                addressString
            );
            jsonOutput = concat(jsonOutput, jsonPair);

            if (i < contractAddresses.length - 1) {
                jsonOutput = concat(jsonOutput, ",");
            }
        }
        jsonOutput = concat(jsonOutput, "}");

        // Constructing the full JSON output
        // // string memory jsonOutput = string(
        // //     abi.encodePacked(
        // //         '{"Coupon":"',
        // //         addressToString.toAsciiString(address(coupon)),
        // //         '", "Issuer":"',
        // //         addressToString.toAsciiString(address(issuer)),
        // //         '", "Multicall":"',
        // //         addressToString.toAsciiString(multicall2Address),
        // //         '", "msgsender":"',
        // //         addressToString.toAsciiString(msg.sender),
        // //         '", "Inputs":',
        // //         inputs,
        // //         "}"
        // //     )
        // );
        // vm.writeFile("/home/justin/code/BehodlerReborn/coupon/script/output/deployed_addresses.json", jsonOutput);
        console.log(jsonOutput);
        */
        
    }

    function getJsonPair(
        string memory name,
        string memory value
    ) private pure returns (string memory output) {
        output = concat(name, ":");
        output = concat(output, value);
    }

    function concat(
        string memory lhs,
        string memory rhs
    ) private pure returns (string memory) {
        return string(abi.encodePacked(lhs, rhs));
    }

    function char(bytes1 b) internal pure returns (bytes1 c) {
        if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
        else return bytes1(uint8(b) + 0x57);
    }
}

contract AddressToString {
    // Helper function to convert address to string
    function toAsciiString(address x) public pure returns (string memory) {
        bytes memory s = new bytes(40);
        for (uint i = 0; i < 20; i++) {
            bytes1 b = bytes1(uint8(uint(uint160(x)) / (2 ** (8 * (19 - i)))));
            bytes1 hi = bytes1(uint8(b) / 16);
            bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
            s[2 * i] = char(hi);
            s[2 * i + 1] = char(lo);
        }
        return string(abi.encodePacked("0x", s));
    }

    function char(bytes1 b) internal pure returns (bytes1 c) {
        if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
        else return bytes1(uint8(b) + 0x57);
    }
}

contract DeployMulticall2 is Script {
    function run() external returns (address) {
        // Load bytecode
        bytes
            memory bytecode = hex"608060405234801561001057600080fd5b50610b55806100206000396000f3fe608060405234801561001057600080fd5b50600436106100d45760003560e01c806372425d9d11610081578063bce38bd71161005b578063bce38bd714610181578063c3077fa9146101a1578063ee82ac5e146101b457600080fd5b806372425d9d1461016757806386d516e81461016d578063a8b0574e1461017357600080fd5b8063399542e9116100b2578063399542e91461011757806342cbb15c146101395780634d2301cc1461013f57600080fd5b80630f28c97d146100d9578063252dba42146100ee57806327e86d6e1461010f575b600080fd5b425b6040519081526020015b60405180910390f35b6101016100fc3660046107e3565b6101c6565b6040516100e592919061089a565b6100db610375565b61012a610125366004610922565b610388565b6040516100e5939291906109df565b436100db565b6100db61014d366004610a07565b73ffffffffffffffffffffffffffffffffffffffff163190565b446100db565b456100db565b6040514181526020016100e5565b61019461018f366004610922565b6103a0565b6040516100e59190610a29565b61012a6101af3660046107e3565b61059d565b6100db6101c2366004610a3c565b4090565b8051439060609067ffffffffffffffff8111156101e5576101e56105ba565b60405190808252806020026020018201604052801561021857816020015b60608152602001906001900390816102035790505b50905060005b835181101561036f5760008085838151811061023c5761023c610a55565b60200260200101516000015173ffffffffffffffffffffffffffffffffffffffff1686848151811061027057610270610a55565b6020026020010151602001516040516102899190610a84565b6000604051808303816000865af19150503d80600081146102c6576040519150601f19603f3d011682016040523d82523d6000602084013e6102cb565b606091505b50915091508161033c576040517f08c379a000000000000000000000000000000000000000000000000000000000815260206004820181905260248201527f4d756c746963616c6c206167677265676174653a2063616c6c206661696c656460448201526064015b60405180910390fd5b8084848151811061034f5761034f610a55565b60200260200101819052505050808061036790610acf565b91505061021e565b50915091565b6000610382600143610b08565b40905090565b438040606061039785856103a0565b90509250925092565b6060815167ffffffffffffffff8111156103bc576103bc6105ba565b60405190808252806020026020018201604052801561040257816020015b6040805180820190915260008152606060208201528152602001906001900390816103da5790505b50905060005b82518110156105965760008084838151811061042657610426610a55565b60200260200101516000015173ffffffffffffffffffffffffffffffffffffffff1685848151811061045a5761045a610a55565b6020026020010151602001516040516104739190610a84565b6000604051808303816000865af19150503d80600081146104b0576040519150601f19603f3d011682016040523d82523d6000602084013e6104b5565b606091505b5091509150851561054d578161054d576040517f08c379a000000000000000000000000000000000000000000000000000000000815260206004820152602160248201527f4d756c746963616c6c32206167677265676174653a2063616c6c206661696c6560448201527f64000000000000000000000000000000000000000000000000000000000000006064820152608401610333565b604051806040016040528083151581526020018281525084848151811061057657610576610a55565b60200260200101819052505050808061058e90610acf565b915050610408565b5092915050565b60008060606105ad600185610388565b9196909550909350915050565b7f4e487b7100000000000000000000000000000000000000000000000000000000600052604160045260246000fd5b6040805190810167ffffffffffffffff8111828210171561060c5761060c6105ba565b60405290565b604051601f82017fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffe016810167ffffffffffffffff81118282101715610659576106596105ba565b604052919050565b803573ffffffffffffffffffffffffffffffffffffffff8116811461068557600080fd5b919050565b6000601f838184011261069c57600080fd5b8235602067ffffffffffffffff808311156106b9576106b96105ba565b8260051b6106c8838201610612565b93845286810183019383810190898611156106e257600080fd5b84890192505b858310156107d6578235848111156107005760008081fd5b890160407fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffe0828d0381018213156107375760008081fd5b61073f6105e9565b61074a898501610661565b8152828401358881111561075e5760008081fd5b8085019450508d603f8501126107745760008081fd5b8884013588811115610788576107886105ba565b6107978a848e84011601610612565b92508083528e848287010111156107ae5760008081fd5b808486018b85013760009083018a0152808901919091528452505091840191908401906106e8565b9998505050505050505050565b6000602082840312156107f557600080fd5b813567ffffffffffffffff81111561080c57600080fd5b6108188482850161068a565b949350505050565b60005b8381101561083b578181015183820152602001610823565b8381111561084a576000848401525b50505050565b60008151808452610868816020860160208601610820565b601f017fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffe0169290920160200192915050565b600060408201848352602060408185015281855180845260608601915060608160051b870101935082870160005b82811015610914577fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffa0888703018452610902868351610850565b955092840192908401906001016108c8565b509398975050505050505050565b6000806040838503121561093557600080fd5b8235801515811461094557600080fd5b9150602083013567ffffffffffffffff81111561096157600080fd5b61096d8582860161068a565b9150509250929050565b6000815180845260208085019450848260051b860182860160005b858110156109d2578383038952815180511515845285015160408685018190526109be81860183610850565b9a87019a9450505090840190600101610992565b5090979650505050505050565b8381528260208201526060604082015260006109fe6060830184610977565b95945050505050565b600060208284031215610a1957600080fd5b610a2282610661565b9392505050565b602081526000610a226020830184610977565b600060208284031215610a4e57600080fd5b5035919050565b7f4e487b7100000000000000000000000000000000000000000000000000000000600052603260045260246000fd5b60008251610a96818460208701610820565b9190910192915050565b7f4e487b7100000000000000000000000000000000000000000000000000000000600052601160045260246000fd5b60007fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff821415610b0157610b01610aa0565b5060010190565b600082821015610b1a57610b1a610aa0565b50039056fea2646970667358221220e7d0aaf55c82be59048620e7f021718b1813ee902147f84cead4ad8176f7682e64736f6c634300080a0033";

        // Deploy the contract using low-level call
        (bool success, address deployedAddress) = deployBytecode(bytecode);
        require(success, "Deployment failed");

        return deployedAddress;
    }

    function deployBytecode(
        bytes memory bytecode
    ) internal returns (bool, address) {
        address addr;
        assembly {
            addr := create(0, add(bytecode, 0x20), mload(bytecode))
            if iszero(extcodesize(addr)) {
                revert(0, 0)
            }
        }
        return (true, addr);
    }
}
