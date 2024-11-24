"use client";
import {
  type BaseError,
  useWriteContract,
  useWaitForTransactionReceipt,
  useReadContract,
  useAccount,
} from "wagmi";

import React, { useState } from "react";
import CollateralSafekeep from "@/abi/CollateralSafekeep.json";
import { parseEther } from "viem";

const csk = {
  address: "0x2F15F0B2492694d65824C71aa41DDc848cb47614",
  abi: CollateralSafekeep,
} as const;

const chains = [
  { name: "Optimism Sepolia", logo: "/borrow.png", eid: 40232 },
  { name: "Ethereum Sepolia", logo: "/borrow.png", eid: 40161 },
  { name: "Base Sepolia", logo: "/borrow.png", eid: 0 },
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

  const mint = async (e: React.FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    const formData = new FormData(e.target as HTMLFormElement);
    const INDAIAmount = formData.get("INDAIAmount") as string;
    setAmount(INDAIAmount);
    if (selectedChainEid === null) {
      alert("Please select a chain.");
      return;
    } else if (selectedChainEid == 0) {
      try {
        await writeContract({
          ...csk,
          functionName: "mintRupioOnHomeChain",
          account: address,
          args: [BigInt(INDAIAmount)],
        });
      } catch (error) {
        console.error("Error:", error);
      }
    } else {
      try {
        await writeContract({
          ...csk,
          functionName: "mintRupioOnDifferentChain",
          value: parseEther("0.001"),
          args: [BigInt(INDAIAmount), BigInt(selectedChainEid)],
        });
      } catch (error) {
        console.error("Error:", error);
      }
    }
  };
  const burn = async (e: React.FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    const formData = new FormData(e.target as HTMLFormElement);
    const INDAIAmount = formData.get("INDAIAmount") as string;
    setAmount(INDAIAmount);

    try {
      await writeContract({
        ...csk,
        functionName: "burnRupioAndRelieveCollateral",
        args: [BigInt(INDAIAmount)],
      });
    } catch (error) {
      console.error("Error:", error);
    }
  };
  const displayAmount = amount ? amount : "0";
  const { address } = useAccount();
  const { data: maxMintableRupio }: any = useReadContract({
    ...csk,
    functionName: "getMaxMintableRupio",
    args: [address],
  });
  const { data: vault }: any = useReadContract({
    ...csk,
    functionName: "getVaultDetailsForTheUser",
    account: address,
  });

  return (
    <div className="h-full p-10 flex flex-col items-center justify-center">
      <div className="flex flex-row gap-10">
        <div className="bg-transparent bg-opacity-10 px-8 py-6 rounded-3xl space-y-3 border-2 border-[var(--secondary)] w-[450px]">
          <h4>Mint Rupio</h4>
          <hr className="border-t-1 border-gray-300 my-4" />

          <p className="font-bold">Already have ETH locked?</p>
          <div className=" flex justify-between ">
            <p>Max Mintable Rupio</p>
            <p className="font-bold">
              {(Number(maxMintableRupio?.toString()) / 10 ** 8).toFixed(2)} RUP
            </p>
          </div>
          <hr className="border-t-[0.1px] border-gray-300 my-4" />

          <p className="text-sm">
            FYI: You need to have some ETH as collateral before you can mint
            Rupio.
          </p>
          <form className="mt-4 space-y-4" onSubmit={mint}>
            <div className="bg-gray-800 px-4 py-3 flex flex-row justify-between">
              <input
                className="bg-transparent"
                name="INDAIAmount"
                placeholder="Amount"
                onChange={(e) => setAmount(e.target.value)}
                required
              />

              <ChainDropdown onSelectChain={setSelectedChainEid} />
            </div>
            <div className="flex flex-row justify-between items-center">
              <p className="text-lg">
                {displayAmount} Rupio on {getChainNameByEid(selectedChainEid)}
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
          <h4>Burn Rupio</h4>
          <hr className="border-t-1 border-gray-300 my-4" />

          <p className="">
            Burn Rupio and relieve ETH collateral on base sepolia.
          </p>
          <div className=" flex justify-between ">
            <p>Current Balance</p>
            <p className="font-bold">
              {" "}
              {(Number(vault?.rupioIssued.toString()) / 10 ** 8).toFixed(2)} RUP
            </p>
          </div>
          <div className=" flex justify-between ">
            <p>Vault Health</p>
            <p className="font-bold">
              {" "}
              {Number(vault?.vaultHealth.toString()).toFixed(2)}
            </p>
          </div>
          <hr className="border-t-[0.1px] border-gray-300 my-4" />

          <form className="mt-4 space-y-4" onSubmit={burn}>
            <div className="bg-gray-800 pl-4  flex flex-row justify-between">
              <input
                className="bg-transparent"
                name="INDAIAmount"
                placeholder="Amount"
                required
              />
              <button
                disabled={isPending}
                type="submit"
                className="ml-4 p-x-3 py-2 bg-red-800 text-white rounded-xl "
              >
                {isPending ? "Confirming..." : "Burn"}
              </button>
            </div>
            <div className="flex flex-row justify-between items-center"></div>
            {isConfirming && <div>Waiting for confirmation...</div>}
            {isConfirmed && <div>Transaction confirmed.</div>}
            {error && (
              <div>
                Error: {(error as BaseError).shortMessage || error.message}
              </div>
            )}
            {hash && <div>Transaction Hash: {hash}</div>}
          </form>

          {isConfirming && <div>Waiting for confirmation...</div>}
          {isConfirmed && <div>Transaction confirmed.</div>}
          {error && (
            <div>
              Error: {(error as BaseError).shortMessage || error.message}
            </div>
          )}
          {hash && <div>Transaction Hash: {hash}</div>}
        </div>
      </div>
    </div>
  );
}

export default LockETH;
