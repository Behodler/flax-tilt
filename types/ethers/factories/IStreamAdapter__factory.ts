/* Autogenerated file. Do not edit manually. */
/* tslint:disable */
/* eslint-disable */

import { Contract, Signer, utils } from "ethers";
import type { Provider } from "@ethersproject/providers";
import type {
  IStreamAdapter,
  IStreamAdapterInterface,
} from "../IStreamAdapter";

const _abi = [
  {
    type: "function",
    name: "lock",
    inputs: [
      {
        name: "recipient",
        type: "address",
        internalType: "address",
      },
      {
        name: "amount",
        type: "uint256",
        internalType: "uint256",
      },
      {
        name: "durationInDays",
        type: "uint256",
        internalType: "uint256",
      },
    ],
    outputs: [
      {
        name: "id",
        type: "uint256",
        internalType: "uint256",
      },
    ],
    stateMutability: "nonpayable",
  },
] as const;

export class IStreamAdapter__factory {
  static readonly abi = _abi;
  static createInterface(): IStreamAdapterInterface {
    return new utils.Interface(_abi) as IStreamAdapterInterface;
  }
  static connect(
    address: string,
    signerOrProvider: Signer | Provider
  ): IStreamAdapter {
    return new Contract(address, _abi, signerOrProvider) as IStreamAdapter;
  }
}
