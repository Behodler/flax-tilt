/* Autogenerated file. Do not edit manually. */
/* tslint:disable */
/* eslint-disable */
import type {
  BaseContract,
  BigNumber,
  BigNumberish,
  BytesLike,
  CallOverrides,
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

export interface LockupStorageInterface extends utils.Interface {
  functions: {
    "planBalanceOf(uint256,uint256,uint256)": FunctionFragment;
    "planEnd(uint256)": FunctionFragment;
    "plans(uint256)": FunctionFragment;
    "segmentOriginalEnd(uint256)": FunctionFragment;
  };

  getFunction(
    nameOrSignatureOrTopic:
      | "planBalanceOf"
      | "planEnd"
      | "plans"
      | "segmentOriginalEnd"
  ): FunctionFragment;

  encodeFunctionData(
    functionFragment: "planBalanceOf",
    values: [BigNumberish, BigNumberish, BigNumberish]
  ): string;
  encodeFunctionData(
    functionFragment: "planEnd",
    values: [BigNumberish]
  ): string;
  encodeFunctionData(functionFragment: "plans", values: [BigNumberish]): string;
  encodeFunctionData(
    functionFragment: "segmentOriginalEnd",
    values: [BigNumberish]
  ): string;

  decodeFunctionResult(
    functionFragment: "planBalanceOf",
    data: BytesLike
  ): Result;
  decodeFunctionResult(functionFragment: "planEnd", data: BytesLike): Result;
  decodeFunctionResult(functionFragment: "plans", data: BytesLike): Result;
  decodeFunctionResult(
    functionFragment: "segmentOriginalEnd",
    data: BytesLike
  ): Result;

  events: {
    "PlanCreated(uint256,address,address,uint256,uint256,uint256,uint256,uint256,uint256)": EventFragment;
    "PlanRedeemed(uint256,uint256,uint256,uint256)": EventFragment;
    "PlanSegmented(uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256)": EventFragment;
    "PlansCombined(uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256)": EventFragment;
  };

  getEvent(nameOrSignatureOrTopic: "PlanCreated"): EventFragment;
  getEvent(nameOrSignatureOrTopic: "PlanRedeemed"): EventFragment;
  getEvent(nameOrSignatureOrTopic: "PlanSegmented"): EventFragment;
  getEvent(nameOrSignatureOrTopic: "PlansCombined"): EventFragment;
}

export interface PlanCreatedEventObject {
  id: BigNumber;
  recipient: string;
  token: string;
  amount: BigNumber;
  start: BigNumber;
  cliff: BigNumber;
  end: BigNumber;
  rate: BigNumber;
  period: BigNumber;
}
export type PlanCreatedEvent = TypedEvent<
  [
    BigNumber,
    string,
    string,
    BigNumber,
    BigNumber,
    BigNumber,
    BigNumber,
    BigNumber,
    BigNumber
  ],
  PlanCreatedEventObject
>;

export type PlanCreatedEventFilter = TypedEventFilter<PlanCreatedEvent>;

export interface PlanRedeemedEventObject {
  id: BigNumber;
  amountRedeemed: BigNumber;
  planRemainder: BigNumber;
  resetDate: BigNumber;
}
export type PlanRedeemedEvent = TypedEvent<
  [BigNumber, BigNumber, BigNumber, BigNumber],
  PlanRedeemedEventObject
>;

export type PlanRedeemedEventFilter = TypedEventFilter<PlanRedeemedEvent>;

export interface PlanSegmentedEventObject {
  id: BigNumber;
  segmentId: BigNumber;
  newPlanAmount: BigNumber;
  newPlanRate: BigNumber;
  segmentAmount: BigNumber;
  segmentRate: BigNumber;
  start: BigNumber;
  cliff: BigNumber;
  period: BigNumber;
  newPlanEnd: BigNumber;
  segmentEnd: BigNumber;
}
export type PlanSegmentedEvent = TypedEvent<
  [
    BigNumber,
    BigNumber,
    BigNumber,
    BigNumber,
    BigNumber,
    BigNumber,
    BigNumber,
    BigNumber,
    BigNumber,
    BigNumber,
    BigNumber
  ],
  PlanSegmentedEventObject
>;

export type PlanSegmentedEventFilter = TypedEventFilter<PlanSegmentedEvent>;

export interface PlansCombinedEventObject {
  id0: BigNumber;
  id1: BigNumber;
  survivingId: BigNumber;
  amount: BigNumber;
  rate: BigNumber;
  start: BigNumber;
  cliff: BigNumber;
  period: BigNumber;
  end: BigNumber;
}
export type PlansCombinedEvent = TypedEvent<
  [
    BigNumber,
    BigNumber,
    BigNumber,
    BigNumber,
    BigNumber,
    BigNumber,
    BigNumber,
    BigNumber,
    BigNumber
  ],
  PlansCombinedEventObject
>;

export type PlansCombinedEventFilter = TypedEventFilter<PlansCombinedEvent>;

export interface LockupStorage extends BaseContract {
  connect(signerOrProvider: Signer | Provider | string): this;
  attach(addressOrName: string): this;
  deployed(): Promise<this>;

  interface: LockupStorageInterface;

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
    planBalanceOf(
      planId: BigNumberish,
      timeStamp: BigNumberish,
      redemptionTime: BigNumberish,
      overrides?: CallOverrides
    ): Promise<
      [BigNumber, BigNumber, BigNumber] & {
        balance: BigNumber;
        remainder: BigNumber;
        latestUnlock: BigNumber;
      }
    >;

    planEnd(
      planId: BigNumberish,
      overrides?: CallOverrides
    ): Promise<[BigNumber] & { end: BigNumber }>;

    plans(
      arg0: BigNumberish,
      overrides?: CallOverrides
    ): Promise<
      [string, BigNumber, BigNumber, BigNumber, BigNumber, BigNumber] & {
        token: string;
        amount: BigNumber;
        start: BigNumber;
        cliff: BigNumber;
        rate: BigNumber;
        period: BigNumber;
      }
    >;

    segmentOriginalEnd(
      arg0: BigNumberish,
      overrides?: CallOverrides
    ): Promise<[BigNumber]>;
  };

  planBalanceOf(
    planId: BigNumberish,
    timeStamp: BigNumberish,
    redemptionTime: BigNumberish,
    overrides?: CallOverrides
  ): Promise<
    [BigNumber, BigNumber, BigNumber] & {
      balance: BigNumber;
      remainder: BigNumber;
      latestUnlock: BigNumber;
    }
  >;

  planEnd(planId: BigNumberish, overrides?: CallOverrides): Promise<BigNumber>;

  plans(
    arg0: BigNumberish,
    overrides?: CallOverrides
  ): Promise<
    [string, BigNumber, BigNumber, BigNumber, BigNumber, BigNumber] & {
      token: string;
      amount: BigNumber;
      start: BigNumber;
      cliff: BigNumber;
      rate: BigNumber;
      period: BigNumber;
    }
  >;

  segmentOriginalEnd(
    arg0: BigNumberish,
    overrides?: CallOverrides
  ): Promise<BigNumber>;

  callStatic: {
    planBalanceOf(
      planId: BigNumberish,
      timeStamp: BigNumberish,
      redemptionTime: BigNumberish,
      overrides?: CallOverrides
    ): Promise<
      [BigNumber, BigNumber, BigNumber] & {
        balance: BigNumber;
        remainder: BigNumber;
        latestUnlock: BigNumber;
      }
    >;

    planEnd(
      planId: BigNumberish,
      overrides?: CallOverrides
    ): Promise<BigNumber>;

    plans(
      arg0: BigNumberish,
      overrides?: CallOverrides
    ): Promise<
      [string, BigNumber, BigNumber, BigNumber, BigNumber, BigNumber] & {
        token: string;
        amount: BigNumber;
        start: BigNumber;
        cliff: BigNumber;
        rate: BigNumber;
        period: BigNumber;
      }
    >;

    segmentOriginalEnd(
      arg0: BigNumberish,
      overrides?: CallOverrides
    ): Promise<BigNumber>;
  };

  filters: {
    "PlanCreated(uint256,address,address,uint256,uint256,uint256,uint256,uint256,uint256)"(
      id?: BigNumberish | null,
      recipient?: string | null,
      token?: string | null,
      amount?: null,
      start?: null,
      cliff?: null,
      end?: null,
      rate?: null,
      period?: null
    ): PlanCreatedEventFilter;
    PlanCreated(
      id?: BigNumberish | null,
      recipient?: string | null,
      token?: string | null,
      amount?: null,
      start?: null,
      cliff?: null,
      end?: null,
      rate?: null,
      period?: null
    ): PlanCreatedEventFilter;

    "PlanRedeemed(uint256,uint256,uint256,uint256)"(
      id?: BigNumberish | null,
      amountRedeemed?: null,
      planRemainder?: null,
      resetDate?: null
    ): PlanRedeemedEventFilter;
    PlanRedeemed(
      id?: BigNumberish | null,
      amountRedeemed?: null,
      planRemainder?: null,
      resetDate?: null
    ): PlanRedeemedEventFilter;

    "PlanSegmented(uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256)"(
      id?: BigNumberish | null,
      segmentId?: BigNumberish | null,
      newPlanAmount?: null,
      newPlanRate?: null,
      segmentAmount?: null,
      segmentRate?: null,
      start?: null,
      cliff?: null,
      period?: null,
      newPlanEnd?: null,
      segmentEnd?: null
    ): PlanSegmentedEventFilter;
    PlanSegmented(
      id?: BigNumberish | null,
      segmentId?: BigNumberish | null,
      newPlanAmount?: null,
      newPlanRate?: null,
      segmentAmount?: null,
      segmentRate?: null,
      start?: null,
      cliff?: null,
      period?: null,
      newPlanEnd?: null,
      segmentEnd?: null
    ): PlanSegmentedEventFilter;

    "PlansCombined(uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256)"(
      id0?: BigNumberish | null,
      id1?: BigNumberish | null,
      survivingId?: BigNumberish | null,
      amount?: null,
      rate?: null,
      start?: null,
      cliff?: null,
      period?: null,
      end?: null
    ): PlansCombinedEventFilter;
    PlansCombined(
      id0?: BigNumberish | null,
      id1?: BigNumberish | null,
      survivingId?: BigNumberish | null,
      amount?: null,
      rate?: null,
      start?: null,
      cliff?: null,
      period?: null,
      end?: null
    ): PlansCombinedEventFilter;
  };

  estimateGas: {
    planBalanceOf(
      planId: BigNumberish,
      timeStamp: BigNumberish,
      redemptionTime: BigNumberish,
      overrides?: CallOverrides
    ): Promise<BigNumber>;

    planEnd(
      planId: BigNumberish,
      overrides?: CallOverrides
    ): Promise<BigNumber>;

    plans(arg0: BigNumberish, overrides?: CallOverrides): Promise<BigNumber>;

    segmentOriginalEnd(
      arg0: BigNumberish,
      overrides?: CallOverrides
    ): Promise<BigNumber>;
  };

  populateTransaction: {
    planBalanceOf(
      planId: BigNumberish,
      timeStamp: BigNumberish,
      redemptionTime: BigNumberish,
      overrides?: CallOverrides
    ): Promise<PopulatedTransaction>;

    planEnd(
      planId: BigNumberish,
      overrides?: CallOverrides
    ): Promise<PopulatedTransaction>;

    plans(
      arg0: BigNumberish,
      overrides?: CallOverrides
    ): Promise<PopulatedTransaction>;

    segmentOriginalEnd(
      arg0: BigNumberish,
      overrides?: CallOverrides
    ): Promise<PopulatedTransaction>;
  };
}
