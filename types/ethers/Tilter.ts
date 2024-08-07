/* Autogenerated file. Do not edit manually. */
/* tslint:disable */
/* eslint-disable */
import type {
  BaseContract,
  BigNumber,
  BigNumberish,
  BytesLike,
  CallOverrides,
  ContractTransaction,
  Overrides,
  PayableOverrides,
  PopulatedTransaction,
  Signer,
  utils,
} from "ethers";
import type {
  FunctionFragment,
  Result,
  EventFragment,
} from "@ethersproject/abi";
import type { Listener, Provider } from "@ethersproject/providers";
import type {
  TypedEventFilter,
  TypedEvent,
  TypedListener,
  OnEvent,
} from "./common";

export declare namespace ITilter {
  export type OracleSetStruct = { flx_ref_token: string; oracle: string };

  export type OracleSetStructOutput = [string, string] & {
    flx_ref_token: string;
    oracle: string;
  };
}

export interface TilterInterface extends utils.Interface {
  functions: {
    "VARS()": FunctionFragment;
    "configure(address,address,address,address)": FunctionFragment;
    "issue(address,uint256,address)": FunctionFragment;
    "owner()": FunctionFragment;
    "refValueOfTilt(uint256,bool)": FunctionFragment;
    "renounceOwnership()": FunctionFragment;
    "setEnabled(bool)": FunctionFragment;
    "transferOwnership(address)": FunctionFragment;
  };

  getFunction(
    nameOrSignatureOrTopic:
      | "VARS"
      | "configure"
      | "issue"
      | "owner"
      | "refValueOfTilt"
      | "renounceOwnership"
      | "setEnabled"
      | "transferOwnership"
  ): FunctionFragment;

  encodeFunctionData(functionFragment: "VARS", values?: undefined): string;
  encodeFunctionData(
    functionFragment: "configure",
    values: [string, string, string, string]
  ): string;
  encodeFunctionData(
    functionFragment: "issue",
    values: [string, BigNumberish, string]
  ): string;
  encodeFunctionData(functionFragment: "owner", values?: undefined): string;
  encodeFunctionData(
    functionFragment: "refValueOfTilt",
    values: [BigNumberish, boolean]
  ): string;
  encodeFunctionData(
    functionFragment: "renounceOwnership",
    values?: undefined
  ): string;
  encodeFunctionData(functionFragment: "setEnabled", values: [boolean]): string;
  encodeFunctionData(
    functionFragment: "transferOwnership",
    values: [string]
  ): string;

  decodeFunctionResult(functionFragment: "VARS", data: BytesLike): Result;
  decodeFunctionResult(functionFragment: "configure", data: BytesLike): Result;
  decodeFunctionResult(functionFragment: "issue", data: BytesLike): Result;
  decodeFunctionResult(functionFragment: "owner", data: BytesLike): Result;
  decodeFunctionResult(
    functionFragment: "refValueOfTilt",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "renounceOwnership",
    data: BytesLike
  ): Result;
  decodeFunctionResult(functionFragment: "setEnabled", data: BytesLike): Result;
  decodeFunctionResult(
    functionFragment: "transferOwnership",
    data: BytesLike
  ): Result;

  events: {
    "OwnershipTransferred(address,address)": EventFragment;
  };

  getEvent(nameOrSignatureOrTopic: "OwnershipTransferred"): EventFragment;
}

export interface OwnershipTransferredEventObject {
  previousOwner: string;
  newOwner: string;
}
export type OwnershipTransferredEvent = TypedEvent<
  [string, string],
  OwnershipTransferredEventObject
>;

export type OwnershipTransferredEventFilter =
  TypedEventFilter<OwnershipTransferredEvent>;

export interface Tilter extends BaseContract {
  connect(signerOrProvider: Signer | Provider | string): this;
  attach(addressOrName: string): this;
  deployed(): Promise<this>;

  interface: TilterInterface;

  queryFilter<TEvent extends TypedEvent>(
    event: TypedEventFilter<TEvent>,
    fromBlockOrBlockhash?: string | number | undefined,
    toBlock?: string | number | undefined
  ): Promise<Array<TEvent>>;

  listeners<TEvent extends TypedEvent>(
    eventFilter?: TypedEventFilter<TEvent>
  ): Array<TypedListener<TEvent>>;
  listeners(eventName?: string): Array<Listener>;
  removeAllListeners<TEvent extends TypedEvent>(
    eventFilter: TypedEventFilter<TEvent>
  ): this;
  removeAllListeners(eventName?: string): this;
  off: OnEvent<this>;
  on: OnEvent<this>;
  once: OnEvent<this>;
  removeListener: OnEvent<this>;

  functions: {
    VARS(
      overrides?: CallOverrides
    ): Promise<
      [
        string,
        string,
        string,
        string,
        ITilter.OracleSetStructOutput,
        string
      ] & {
        ref_token: string;
        factory: string;
        router: string;
        flax: string;
        oracleSet: ITilter.OracleSetStructOutput;
        issuer: string;
      }
    >;

    configure(
      ref_token: string,
      flx: string,
      oracle: string,
      issuer: string,
      overrides?: Overrides & { from?: string }
    ): Promise<ContractTransaction>;

    issue(
      inputToken: string,
      amount: BigNumberish,
      recipient: string,
      overrides?: PayableOverrides & { from?: string }
    ): Promise<ContractTransaction>;

    owner(overrides?: CallOverrides): Promise<[string]>;

    refValueOfTilt(
      ref_amount: BigNumberish,
      preview: boolean,
      overrides?: CallOverrides
    ): Promise<
      [BigNumber, BigNumber] & {
        flax_new_balance: BigNumber;
        lpTokens_created: BigNumber;
      }
    >;

    renounceOwnership(
      overrides?: Overrides & { from?: string }
    ): Promise<ContractTransaction>;

    setEnabled(
      enabled: boolean,
      overrides?: Overrides & { from?: string }
    ): Promise<ContractTransaction>;

    transferOwnership(
      newOwner: string,
      overrides?: Overrides & { from?: string }
    ): Promise<ContractTransaction>;
  };

  VARS(
    overrides?: CallOverrides
  ): Promise<
    [string, string, string, string, ITilter.OracleSetStructOutput, string] & {
      ref_token: string;
      factory: string;
      router: string;
      flax: string;
      oracleSet: ITilter.OracleSetStructOutput;
      issuer: string;
    }
  >;

  configure(
    ref_token: string,
    flx: string,
    oracle: string,
    issuer: string,
    overrides?: Overrides & { from?: string }
  ): Promise<ContractTransaction>;

  issue(
    inputToken: string,
    amount: BigNumberish,
    recipient: string,
    overrides?: PayableOverrides & { from?: string }
  ): Promise<ContractTransaction>;

  owner(overrides?: CallOverrides): Promise<string>;

  refValueOfTilt(
    ref_amount: BigNumberish,
    preview: boolean,
    overrides?: CallOverrides
  ): Promise<
    [BigNumber, BigNumber] & {
      flax_new_balance: BigNumber;
      lpTokens_created: BigNumber;
    }
  >;

  renounceOwnership(
    overrides?: Overrides & { from?: string }
  ): Promise<ContractTransaction>;

  setEnabled(
    enabled: boolean,
    overrides?: Overrides & { from?: string }
  ): Promise<ContractTransaction>;

  transferOwnership(
    newOwner: string,
    overrides?: Overrides & { from?: string }
  ): Promise<ContractTransaction>;

  callStatic: {
    VARS(
      overrides?: CallOverrides
    ): Promise<
      [
        string,
        string,
        string,
        string,
        ITilter.OracleSetStructOutput,
        string
      ] & {
        ref_token: string;
        factory: string;
        router: string;
        flax: string;
        oracleSet: ITilter.OracleSetStructOutput;
        issuer: string;
      }
    >;

    configure(
      ref_token: string,
      flx: string,
      oracle: string,
      issuer: string,
      overrides?: CallOverrides
    ): Promise<void>;

    issue(
      inputToken: string,
      amount: BigNumberish,
      recipient: string,
      overrides?: CallOverrides
    ): Promise<void>;

    owner(overrides?: CallOverrides): Promise<string>;

    refValueOfTilt(
      ref_amount: BigNumberish,
      preview: boolean,
      overrides?: CallOverrides
    ): Promise<
      [BigNumber, BigNumber] & {
        flax_new_balance: BigNumber;
        lpTokens_created: BigNumber;
      }
    >;

    renounceOwnership(overrides?: CallOverrides): Promise<void>;

    setEnabled(enabled: boolean, overrides?: CallOverrides): Promise<void>;

    transferOwnership(
      newOwner: string,
      overrides?: CallOverrides
    ): Promise<void>;
  };

  filters: {
    "OwnershipTransferred(address,address)"(
      previousOwner?: string | null,
      newOwner?: string | null
    ): OwnershipTransferredEventFilter;
    OwnershipTransferred(
      previousOwner?: string | null,
      newOwner?: string | null
    ): OwnershipTransferredEventFilter;
  };

  estimateGas: {
    VARS(overrides?: CallOverrides): Promise<BigNumber>;

    configure(
      ref_token: string,
      flx: string,
      oracle: string,
      issuer: string,
      overrides?: Overrides & { from?: string }
    ): Promise<BigNumber>;

    issue(
      inputToken: string,
      amount: BigNumberish,
      recipient: string,
      overrides?: PayableOverrides & { from?: string }
    ): Promise<BigNumber>;

    owner(overrides?: CallOverrides): Promise<BigNumber>;

    refValueOfTilt(
      ref_amount: BigNumberish,
      preview: boolean,
      overrides?: CallOverrides
    ): Promise<BigNumber>;

    renounceOwnership(
      overrides?: Overrides & { from?: string }
    ): Promise<BigNumber>;

    setEnabled(
      enabled: boolean,
      overrides?: Overrides & { from?: string }
    ): Promise<BigNumber>;

    transferOwnership(
      newOwner: string,
      overrides?: Overrides & { from?: string }
    ): Promise<BigNumber>;
  };

  populateTransaction: {
    VARS(overrides?: CallOverrides): Promise<PopulatedTransaction>;

    configure(
      ref_token: string,
      flx: string,
      oracle: string,
      issuer: string,
      overrides?: Overrides & { from?: string }
    ): Promise<PopulatedTransaction>;

    issue(
      inputToken: string,
      amount: BigNumberish,
      recipient: string,
      overrides?: PayableOverrides & { from?: string }
    ): Promise<PopulatedTransaction>;

    owner(overrides?: CallOverrides): Promise<PopulatedTransaction>;

    refValueOfTilt(
      ref_amount: BigNumberish,
      preview: boolean,
      overrides?: CallOverrides
    ): Promise<PopulatedTransaction>;

    renounceOwnership(
      overrides?: Overrides & { from?: string }
    ): Promise<PopulatedTransaction>;

    setEnabled(
      enabled: boolean,
      overrides?: Overrides & { from?: string }
    ): Promise<PopulatedTransaction>;

    transferOwnership(
      newOwner: string,
      overrides?: Overrides & { from?: string }
    ): Promise<PopulatedTransaction>;
  };
}
