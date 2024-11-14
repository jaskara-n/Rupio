"use client";
import {
  type BaseError,
  useWriteContract,
  useWaitForTransactionReceipt,
} from "wagmi";
import React, { useState } from "react";
import CollateralSafekeep from "@/abi/CollateralSafekeep.json";

const csk = {
  address: "0x5F0f545F044628b8DF84F1933887eC6aa9E9449D",
  abi: CollateralSafekeep,
} as const;

const chains = [
  { name: "Optimism Sepolia", logo: "/borrow.png", eid: 1234 },
  { name: "Ethereum Sepolia", logo: "/borrow.png", eid: 5678 },
  { name: "Base Sepolia", logo: "/borrow.png", eid: 91011 },
];

// Dropdown Component with TypeScript
interface ChainDropdownProps {
  onSelectChain: (eid: number) => void;
}

const ChainDropdown: React.FC<ChainDropdownProps> = ({ onSelectChain }) => {
  const [selectedChain, setSelectedChain] = useState<number | null>(null);

  const handleSelect = (event: React.ChangeEvent<HTMLSelectElement>) => {
    const eid = parseInt(event.target.value);
    setSelectedChain(eid);
    onSelectChain(eid);
  };

  return (
    <select
      className="bg-transparent text-gray-400"
      onChange={handleSelect}
      value={selectedChain || ""}
    >
      <option value="" disabled>
        Select Chain
      </option>
      {chains.map((chain) => (
        <option key={chain.eid} value={chain.eid}>
          {chain.name}
        </option>
      ))}
    </select>
  );
};

// Main Component
function LockETH() {
  const getChainNameByEid = (eid: number | null) => {
    const chain = chains.find((chain) => chain.eid === eid);
    return chain ? chain.name : "Unknown Chain"; // Default to "Unknown Chain" if not found
  };
  const { data: hash, isPending, writeContract, error } = useWriteContract();
  const { isLoading: isConfirming, isSuccess: isConfirmed } =
    useWaitForTransactionReceipt({
      hash,
    });

  const [selectedChainEid, setSelectedChainEid] = useState<number | null>(null);
  const [amount, setAmount] = useState("");

  const submit = async (e: React.FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    const formData = new FormData(e.target as HTMLFormElement);
    const INDAIAmount = formData.get("INDAIAmount") as string;
    setAmount(INDAIAmount);
    if (selectedChainEid === null) {
      alert("Please select a chain.");
      return;
    }

    try {
      await writeContract({
        ...csk,
        functionName: "mintIndai",
        args: [BigInt(INDAIAmount), selectedChainEid],
      });
    } catch (error) {
      console.error("Error:", error);
    }
  };
  const displayAmount = amount ? amount : "0";

  return (
    <div className="h-full p-10 flex flex-col items-center justify-center">
      <div className="flex flex-row gap-10">
        <div className="bg-transparent bg-opacity-10 px-8 py-6 rounded-3xl space-y-3 border-2 border-[var(--secondary)] w-[450px]">
          <h4>Mint Indai</h4>
          <hr className="border-t-1 border-gray-300 my-4" />

          <p className="font-bold">Already have ETH locked?</p>
          <div className=" flex justify-between ">
            <p>Max Mintable Indai</p>
            <p className="font-bold">400 INDAI</p>
          </div>
          <hr className="border-t-[0.1px] border-gray-300 my-4" />

          <p className="text-sm">
            FYI: You need to have some ETH as collateral before you can mint
            Indai.
          </p>
          <form className="mt-4 space-y-4" onSubmit={submit}>
            <div className="bg-gray-800 px-4 py-3 flex flex-row justify-between">
              <input
                className="bg-transparent"
                name="INDAIAmount"
                placeholder="Amount"
                required
              />

              <ChainDropdown onSelectChain={setSelectedChainEid} />
            </div>
            <div className="flex flex-row justify-between items-center">
              <p className="text-lg">
                {displayAmount} indai on {getChainNameByEid(selectedChainEid)}
              </p>
              <button
                disabled={isPending}
                type="submit"
                className="ml-4 p-x-3 py-2 bg-red-800 text-white rounded-xl "
              >
                {isPending ? "Confirming..." : "Mint"}
              </button>
            </div>
            <hr className="border-t-[0.1px] border-gray-300 my-4" />
            {isConfirming && <div>Waiting for confirmation...</div>}
            {isConfirmed && <div>Transaction confirmed.</div>}
            {error && (
              <div>
                Error: {(error as BaseError).shortMessage || error.message}
              </div>
            )}
            {hash && <div>Transaction Hash: {hash}</div>}
          </form>

          <div className="flex justify-between flex-row items-center">
            <p className="font-bold">Else lock some ETH today!</p>

            <button
              className="primary py-2 px-4 mt-2"
              onClick={() => (window.location.href = "/LockETH")}
            >
              Lock ETH
            </button>
          </div>
        </div>

        <div className="bg-transparent bg-opacity-10 px-8 py-6 rounded-3xl space-y-3 border-2 border-[var(--secondary)] w-[450px]">
          <h4>Mint Indai</h4>
          <hr className="border-t-1 border-gray-300 my-4" />

          <p className="font-bold">Already have ETH locked?</p>
          <div className=" flex justify-between ">
            <p>Max Mintable Indai</p>
            <p className="font-bold">400 INDAI</p>
          </div>
          <hr className="border-t-[0.1px] border-gray-300 my-4" />

          <p className="text-sm">
            FYI: You need to have some ETH as collateral before you can mint
            Indai.
          </p>
          <form className="mt-4 space-y-4" onSubmit={submit}>
            <div className="bg-gray-800 px-4 py-3 flex flex-row justify-between">
              <input
                className="bg-transparent"
                name="INDAIAmount"
                placeholder="Amount"
                required
              />

              <ChainDropdown onSelectChain={setSelectedChainEid} />
            </div>
            <div className="flex flex-row justify-between items-center">
              <p className="text-lg">
                {displayAmount} indai on {getChainNameByEid(selectedChainEid)}
              </p>
              <button
                disabled={isPending}
                type="submit"
                className="ml-4 p-x-3 py-2 bg-red-800 text-white rounded-xl "
              >
                {isPending ? "Confirming..." : "Mint"}
              </button>
            </div>
            <hr className="border-t-[0.1px] border-gray-300 my-4" />
            {isConfirming && <div>Waiting for confirmation...</div>}
            {isConfirmed && <div>Transaction confirmed.</div>}
            {error && (
              <div>
                Error: {(error as BaseError).shortMessage || error.message}
              </div>
            )}
            {hash && <div>Transaction Hash: {hash}</div>}
          </form>

          <div className="flex justify-between flex-row items-center">
            <p className="font-bold">Else lock some ETH today!</p>

            <button
              className="primary py-2 px-4 mt-2"
              onClick={() => (window.location.href = "/LockETH")}
            >
              Lock ETH
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}

export default LockETH;
