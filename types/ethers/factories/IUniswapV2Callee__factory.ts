/* Autogenerated file. Do not edit manually. */
/* tslint:disable */
/* eslint-disable */

import { Contract, Signer, utils } from "ethers";
import type { Provider } from "@ethersproject/providers";
import type {
  IUniswapV2Callee,
  IUniswapV2CalleeInterface,
} from "../IUniswapV2Callee";

const _abi = [
  {
    type: "function",
    name: "uniswapV2Call",
    inputs: [
      {
        name: "sender",
        type: "address",
        internalType: "address",
      },
      {
        name: "amount0",
        type: "uint256",
        internalType: "uint256",
      },
      {
        name: "amount1",
        type: "uint256",
        internalType: "uint256",
      },
      {
        name: "data",
        type: "bytes",
        internalType: "bytes",
      },
    ],
    outputs: [],
    stateMutability: "nonpayable",
  },
] as const;

export class IUniswapV2Callee__factory {
  static readonly abi = _abi;
  static createInterface(): IUniswapV2CalleeInterface {
    return new utils.Interface(_abi) as IUniswapV2CalleeInterface;
  }
  static connect(
    address: string,
    signerOrProvider: Signer | Provider
  ): IUniswapV2Callee {
    return new Contract(address, _abi, signerOrProvider) as IUniswapV2Callee;
  }
}