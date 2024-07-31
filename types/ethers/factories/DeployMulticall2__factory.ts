/* Autogenerated file. Do not edit manually. */
/* tslint:disable */
/* eslint-disable */

import { Contract, Signer, utils } from "ethers";
import type { Provider } from "@ethersproject/providers";
import type {
  DeployMulticall2,
  DeployMulticall2Interface,
} from "../DeployMulticall2";

const _abi = [
  {
    type: "function",
    name: "IS_SCRIPT",
    inputs: [],
    outputs: [
      {
        name: "",
        type: "bool",
        internalType: "bool",
      },
    ],
    stateMutability: "view",
  },
  {
    type: "function",
    name: "run",
    inputs: [],
    outputs: [
      {
        name: "",
        type: "address",
        internalType: "address",
      },
    ],
    stateMutability: "nonpayable",
  },
] as const;

export class DeployMulticall2__factory {
  static readonly abi = _abi;
  static createInterface(): DeployMulticall2Interface {
    return new utils.Interface(_abi) as DeployMulticall2Interface;
  }
  static connect(
    address: string,
    signerOrProvider: Signer | Provider
  ): DeployMulticall2 {
    return new Contract(address, _abi, signerOrProvider) as DeployMulticall2;
  }
}