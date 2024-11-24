"use client";
import React, { useState } from "react";
import { useSwitchChain } from "wagmi";
import { addressToBytes32 } from "@layerzerolabs/lz-v2-utilities";
import { Options } from "@layerzerolabs/lz-v2-utilities";
import { BigNumberish, BytesLike, parseEther } from "ethers";
import Rupio from "@/abi/Rupio.json";
import {
  type BaseError,
  useWriteContract,
  useWaitForTransactionReceipt,
  useAccount,
} from "wagmi";

interface SendParam {
  dstEid: BigNumberish;
  to: BytesLike;
  amountLD: BigNumberish;
  minAmountLD: BigNumberish;
  extraOptions: BytesLike;
  composeMsg: BytesLike;
  oftCmd: BytesLike;
}

interface ChainConfig {
  chainEid: number;
  contractAddress: string;
}

interface ChainsMap {
  [key: number]: ChainConfig;
}

const chainConfigs: ChainsMap = {
  11155111: { chainEid: 1001, contractAddress: "0xBaseSepoliaContract" }, // Base Sepolia example
  // Add more chains as needed
};

function CrossTransferWidget() {
  const { chains, switchChain } = useSwitchChain();
  const [rupioAmount, setRupioAmount] = useState("");
  const [recipientAddress, setRecipientAddress] = useState("");
  const [selectedFromChain, setSelectedFromChain] = useState<number | null>(
    null
  );
  const [selectedToChain, setSelectedToChain] = useState<number | null>(null);

  const rup = {
    address: "0x9BD90ac5435a793333C2F1e59A6e7e5dBAd0AFEa",
    abi: Rupio,
  } as const;

  const { data: hash, isPending, writeContract, error } = useWriteContract();
  const { isLoading: isConfirming, isSuccess: isConfirmed } =
    useWaitForTransactionReceipt({
      hash,
    });
  const { address } = useAccount();

  const handleInputChange = (event: React.ChangeEvent<HTMLInputElement>) => {
    setRupioAmount(event.target.value);
  };

  const handleAddressChange = (event: React.ChangeEvent<HTMLInputElement>) => {
    setRecipientAddress(event.target.value);
  };

  const handleFromChainChange = (
    event: React.ChangeEvent<HTMLSelectElement>
  ) => {
    const chainId = parseInt(event.target.value);
    setSelectedFromChain(chainId);
    const chain = chains.find((c) => c.id === chainId);
    if (chain) switchChain({ chainId: chain.id });
  };

  const handleToChainChange = (event: React.ChangeEvent<HTMLSelectElement>) => {
    setSelectedToChain(parseInt(event.target.value));
  };

  const handleTransact = async () => {
    if (
      selectedFromChain &&
      selectedToChain &&
      rupioAmount &&
      recipientAddress
    ) {
      const fromConfig = chainConfigs[selectedFromChain];
      const toConfig = chainConfigs[selectedToChain];

      // if (!fromConfig || !toConfig) {
      //   console.error("Invalid chain configuration");
      //   alert("Invalid chain configuration");
      //   return;
      // }

      const options = Options.newOptions()
        .addExecutorLzReceiveOption(65000, 0)
        .toBytes();

      const sendParam: SendParam = {
        dstEid: toConfig.chainEid,
        to: addressToBytes32(recipientAddress),
        amountLD: rupioAmount,
        minAmountLD: rupioAmount,
        extraOptions: options,
        composeMsg: "", // Assuming no composed message
        oftCmd: "", // Assuming no OFT command is needed
      };

      console.log("Transaction Details:", {
        fromChain: fromConfig,
        toChain: toConfig,
        sendParam,
      });

      try {
        writeContract({
          ...rup,
          functionName: "send",
          account: address,
          value: parseEther("0.001"), // Ensure gas is sufficient
          args: [sendParam, parseEther("0.001"), address],
        });
      } catch (err) {
        console.error("Transaction failed:", err);
        alert(`Transaction failed: ${err?.toString() || "Unknown error"}`);
      }
    } else {
      console.error("Missing fields for transaction");
      alert("Please fill all fields before transacting.");
    }
  };

  return (
    <div className="flex justify-center items-center h-full p-8">
      <div className="border border-yellow-300 rounded-xl pb-5 px-5 py-4 w-[500px] space-y-3">
        <h3>Cross-Transfer Rupio</h3>
        <div>
          <h3>From</h3>
          <div className="flex items-center bg-opacity-50 p-4 space-x-4 text-white border rounded-xl border-yellow-300">
            <input
              type="text"
              value={rupioAmount}
              onChange={handleInputChange}
              placeholder="0.00"
              className="bg-var[--background] placeholder-black rounded-xl text-black flex-grow focus:outline-none focus:ring-0 bg-[var(--secondary)] px-3 py-2"
            />
            <div className="whitespace-nowrap">{rupioAmount || "0"} RUP</div>
            <div className="relative w-40 overflow-hidden">
              <select
                className="w-full p-2 border border-dotted rounded-xl bg-transparent focus:outline-none focus:ring-0 appearance-none box-border"
                value={selectedFromChain || ""}
                onChange={handleFromChainChange}
              >
                <option value="">Select a chain</option>
                {chains.map((chain) => (
                  <option key={chain.id} value={chain.id}>
                    {chain.name}
                  </option>
                ))}
              </select>
              <span className="absolute inset-y-0 right-3 flex items-center pointer-events-none">
                ▼
              </span>
            </div>
          </div>
        </div>
        <div>
          <h3>To</h3>
          <div className="flex flex-row border border-white rounded-xl px-5 py-4">
            <input
              type="text"
              value={recipientAddress}
              onChange={handleAddressChange}
              placeholder="Recipient Address"
              className="bg-transparent placeholder-white rounded-xl text-white flex-grow focus:outline-none focus:ring-0"
            />
            <div className="relative w-40 overflow-hidden mt-3">
              <select
                className="w-full p-2 border border-dotted rounded-xl bg-transparent focus:outline-none focus:ring-0 appearance-none box-border"
                value={selectedToChain || ""}
                onChange={handleToChainChange}
              >
                <option value="">Select a chain</option>
                {chains.map((chain) => (
                  <option key={chain.id} value={chain.id}>
                    {chain.name}
                  </option>
                ))}
              </select>
              <span className="absolute inset-y-0 right-3 flex items-center pointer-events-none">
                ▼
              </span>
            </div>
          </div>
        </div>
        <button
          className="secondary w-full"
          onClick={handleTransact}
          disabled={
            !selectedFromChain ||
            !selectedToChain ||
            !rupioAmount ||
            !recipientAddress
          }
        >
          Transact
        </button>
      </div>
    </div>
  );
}

export default CrossTransferWidget;
