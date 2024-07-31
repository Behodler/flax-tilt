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

export declare namespace FixedPoint {
  export type Uq112x112Struct = { _x: BigNumberish };

  export type Uq112x112StructOutput = [BigNumber] & { _x: BigNumber };
}

export interface OracleInterface extends utils.Interface {
  functions: {
    "RegisterPair(address,uint256)": FunctionFragment;
    "factory()": FunctionFragment;
    "getLastUpdate(address,address)": FunctionFragment;
    "owner()": FunctionFragment;
    "pairMeasurements(address)": FunctionFragment;
    "renounceOwnership()": FunctionFragment;
    "safeConsult(address,address,uint256)": FunctionFragment;
    "transferOwnership(address)": FunctionFragment;
    "uniSort(address,address)": FunctionFragment;
    "unsafeConsult(address,address,uint256)": FunctionFragment;
    "update(address,address)": FunctionFragment;
    "updatePair(address)": FunctionFragment;
  };

  getFunction(
    nameOrSignatureOrTopic:
      | "RegisterPair"
      | "factory"
      | "getLastUpdate"
      | "owner"
      | "pairMeasurements"
      | "renounceOwnership"
      | "safeConsult"
      | "transferOwnership"
      | "uniSort"
      | "unsafeConsult"
      | "update"
      | "updatePair"
  ): FunctionFragment;

  encodeFunctionData(
    functionFragment: "RegisterPair",
    values: [string, BigNumberish]
  ): string;
  encodeFunctionData(functionFragment: "factory", values?: undefined): string;
  encodeFunctionData(
    functionFragment: "getLastUpdate",
    values: [string, string]
  ): string;
  encodeFunctionData(functionFragment: "owner", values?: undefined): string;
  encodeFunctionData(
    functionFragment: "pairMeasurements",
    values: [string]
  ): string;
  encodeFunctionData(
    functionFragment: "renounceOwnership",
    values?: undefined
  ): string;
  encodeFunctionData(
    functionFragment: "safeConsult",
    values: [string, string, BigNumberish]
  ): string;
  encodeFunctionData(
    functionFragment: "transferOwnership",
    values: [string]
  ): string;
  encodeFunctionData(
    functionFragment: "uniSort",
    values: [string, string]
  ): string;
  encodeFunctionData(
    functionFragment: "unsafeConsult",
    values: [string, string, BigNumberish]
  ): string;
  encodeFunctionData(
    functionFragment: "update",
    values: [string, string]
  ): string;
  encodeFunctionData(functionFragment: "updatePair", values: [string]): string;

  decodeFunctionResult(
    functionFragment: "RegisterPair",
    data: BytesLike
  ): Result;
  decodeFunctionResult(functionFragment: "factory", data: BytesLike): Result;
  decodeFunctionResult(
    functionFragment: "getLastUpdate",
    data: BytesLike
  ): Result;
  decodeFunctionResult(functionFragment: "owner", data: BytesLike): Result;
  decodeFunctionResult(
    functionFragment: "pairMeasurements",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "renounceOwnership",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "safeConsult",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "transferOwnership",
    data: BytesLike
  ): Result;
  decodeFunctionResult(functionFragment: "uniSort", data: BytesLike): Result;
  decodeFunctionResult(
    functionFragment: "unsafeConsult",
    data: BytesLike
  ): Result;
  decodeFunctionResult(functionFragment: "update", data: BytesLike): Result;
  decodeFunctionResult(functionFragment: "updatePair", data: BytesLike): Result;

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

export interface Oracle extends BaseContract {
  connect(signerOrProvider: Signer | Provider | string): this;
  attach(addressOrName: string): this;
  deployed(): Promise<this>;

  interface: OracleInterface;

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
    RegisterPair(
      pairAddress: string,
      period: BigNumberish,
      overrides?: Overrides & { from?: string }
    ): Promise<ContractTransaction>;

    factory(overrides?: CallOverrides): Promise<[string]>;

    getLastUpdate(
      token0: string,
      token1: string,
      overrides?: CallOverrides
    ): Promise<[number, BigNumber]>;

    owner(overrides?: CallOverrides): Promise<[string]>;

    pairMeasurements(
      arg0: string,
      overrides?: CallOverrides
    ): Promise<
      [
        BigNumber,
        BigNumber,
        number,
        FixedPoint.Uq112x112StructOutput,
        FixedPoint.Uq112x112StructOutput,
        BigNumber
      ] & {
        price0CumulativeLast: BigNumber;
        price1CumulativeLast: BigNumber;
        blockTimestampLast: number;
        price0Average: FixedPoint.Uq112x112StructOutput;
        price1Average: FixedPoint.Uq112x112StructOutput;
        period: BigNumber;
      }
    >;

    renounceOwnership(
      overrides?: Overrides & { from?: string }
    ): Promise<ContractTransaction>;

    safeConsult(
      tokenIn: string,
      tokenOut: string,
      amountIn: BigNumberish,
      overrides?: CallOverrides
    ): Promise<[BigNumber]>;

    transferOwnership(
      newOwner: string,
      overrides?: Overrides & { from?: string }
    ): Promise<ContractTransaction>;

    uniSort(
      tokenA: string,
      tokenB: string,
      overrides?: CallOverrides
    ): Promise<[string, string] & { token0: string; token1: string }>;

    unsafeConsult(
      tokenIn: string,
      tokenOut: string,
      amountIn: BigNumberish,
      overrides?: CallOverrides
    ): Promise<[BigNumber]>;

    update(
      token0: string,
      token1: string,
      overrides?: Overrides & { from?: string }
    ): Promise<ContractTransaction>;

    updatePair(
      pair: string,
      overrides?: Overrides & { from?: string }
    ): Promise<ContractTransaction>;
  };

  RegisterPair(
    pairAddress: string,
    period: BigNumberish,
    overrides?: Overrides & { from?: string }
  ): Promise<ContractTransaction>;

  factory(overrides?: CallOverrides): Promise<string>;

  getLastUpdate(
    token0: string,
    token1: string,
    overrides?: CallOverrides
  ): Promise<[number, BigNumber]>;

  owner(overrides?: CallOverrides): Promise<string>;

  pairMeasurements(
    arg0: string,
    overrides?: CallOverrides
  ): Promise<
    [
      BigNumber,
      BigNumber,
      number,
      FixedPoint.Uq112x112StructOutput,
      FixedPoint.Uq112x112StructOutput,
      BigNumber
    ] & {
      price0CumulativeLast: BigNumber;
      price1CumulativeLast: BigNumber;
      blockTimestampLast: number;
      price0Average: FixedPoint.Uq112x112StructOutput;
      price1Average: FixedPoint.Uq112x112StructOutput;
      period: BigNumber;
    }
  >;

  renounceOwnership(
    overrides?: Overrides & { from?: string }
  ): Promise<ContractTransaction>;

  safeConsult(
    tokenIn: string,
    tokenOut: string,
    amountIn: BigNumberish,
    overrides?: CallOverrides
  ): Promise<BigNumber>;

  transferOwnership(
    newOwner: string,
    overrides?: Overrides & { from?: string }
  ): Promise<ContractTransaction>;

  uniSort(
    tokenA: string,
    tokenB: string,
    overrides?: CallOverrides
  ): Promise<[string, string] & { token0: string; token1: string }>;

  unsafeConsult(
    tokenIn: string,
    tokenOut: string,
    amountIn: BigNumberish,
    overrides?: CallOverrides
  ): Promise<BigNumber>;

  update(
    token0: string,
    token1: string,
    overrides?: Overrides & { from?: string }
  ): Promise<ContractTransaction>;

  updatePair(
    pair: string,
    overrides?: Overrides & { from?: string }
  ): Promise<ContractTransaction>;

  callStatic: {
    RegisterPair(
      pairAddress: string,
      period: BigNumberish,
      overrides?: CallOverrides
    ): Promise<void>;

    factory(overrides?: CallOverrides): Promise<string>;

    getLastUpdate(
      token0: string,
      token1: string,
      overrides?: CallOverrides
    ): Promise<[number, BigNumber]>;

    owner(overrides?: CallOverrides): Promise<string>;

    pairMeasurements(
      arg0: string,
      overrides?: CallOverrides
    ): Promise<
      [
        BigNumber,
        BigNumber,
        number,
        FixedPoint.Uq112x112StructOutput,
        FixedPoint.Uq112x112StructOutput,
        BigNumber
      ] & {
        price0CumulativeLast: BigNumber;
        price1CumulativeLast: BigNumber;
        blockTimestampLast: number;
        price0Average: FixedPoint.Uq112x112StructOutput;
        price1Average: FixedPoint.Uq112x112StructOutput;
        period: BigNumber;
      }
    >;

    renounceOwnership(overrides?: CallOverrides): Promise<void>;

    safeConsult(
      tokenIn: string,
      tokenOut: string,
      amountIn: BigNumberish,
      overrides?: CallOverrides
    ): Promise<BigNumber>;

    transferOwnership(
      newOwner: string,
      overrides?: CallOverrides
    ): Promise<void>;

    uniSort(
      tokenA: string,
      tokenB: string,
      overrides?: CallOverrides
    ): Promise<[string, string] & { token0: string; token1: string }>;

    unsafeConsult(
      tokenIn: string,
      tokenOut: string,
      amountIn: BigNumberish,
      overrides?: CallOverrides
    ): Promise<BigNumber>;

    update(
      token0: string,
      token1: string,
      overrides?: CallOverrides
    ): Promise<void>;

    updatePair(pair: string, overrides?: CallOverrides): Promise<void>;
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
    RegisterPair(
      pairAddress: string,
      period: BigNumberish,
      overrides?: Overrides & { from?: string }
    ): Promise<BigNumber>;

    factory(overrides?: CallOverrides): Promise<BigNumber>;

    getLastUpdate(
      token0: string,
      token1: string,
      overrides?: CallOverrides
    ): Promise<BigNumber>;

    owner(overrides?: CallOverrides): Promise<BigNumber>;

    pairMeasurements(
      arg0: string,
      overrides?: CallOverrides
    ): Promise<BigNumber>;

    renounceOwnership(
      overrides?: Overrides & { from?: string }
    ): Promise<BigNumber>;

    safeConsult(
      tokenIn: string,
      tokenOut: string,
      amountIn: BigNumberish,
      overrides?: CallOverrides
    ): Promise<BigNumber>;

    transferOwnership(
      newOwner: string,
      overrides?: Overrides & { from?: string }
    ): Promise<BigNumber>;

    uniSort(
      tokenA: string,
      tokenB: string,
      overrides?: CallOverrides
    ): Promise<BigNumber>;

    unsafeConsult(
      tokenIn: string,
      tokenOut: string,
      amountIn: BigNumberish,
      overrides?: CallOverrides
    ): Promise<BigNumber>;

    update(
      token0: string,
      token1: string,
      overrides?: Overrides & { from?: string }
    ): Promise<BigNumber>;

    updatePair(
      pair: string,
      overrides?: Overrides & { from?: string }
    ): Promise<BigNumber>;
  };

  populateTransaction: {
    RegisterPair(
      pairAddress: string,
      period: BigNumberish,
      overrides?: Overrides & { from?: string }
    ): Promise<PopulatedTransaction>;

    factory(overrides?: CallOverrides): Promise<PopulatedTransaction>;

    getLastUpdate(
      token0: string,
      token1: string,
      overrides?: CallOverrides
    ): Promise<PopulatedTransaction>;

    owner(overrides?: CallOverrides): Promise<PopulatedTransaction>;

    pairMeasurements(
      arg0: string,
      overrides?: CallOverrides
    ): Promise<PopulatedTransaction>;

    renounceOwnership(
      overrides?: Overrides & { from?: string }
    ): Promise<PopulatedTransaction>;

    safeConsult(
      tokenIn: string,
      tokenOut: string,
      amountIn: BigNumberish,
      overrides?: CallOverrides
    ): Promise<PopulatedTransaction>;

    transferOwnership(
      newOwner: string,
      overrides?: Overrides & { from?: string }
    ): Promise<PopulatedTransaction>;

    uniSort(
      tokenA: string,
      tokenB: string,
      overrides?: CallOverrides
    ): Promise<PopulatedTransaction>;

    unsafeConsult(
      tokenIn: string,
      tokenOut: string,
      amountIn: BigNumberish,
      overrides?: CallOverrides
    ): Promise<PopulatedTransaction>;

    update(
      token0: string,
      token1: string,
      overrides?: Overrides & { from?: string }
    ): Promise<PopulatedTransaction>;

    updatePair(
      pair: string,
      overrides?: Overrides & { from?: string }
    ): Promise<PopulatedTransaction>;
  };
}
