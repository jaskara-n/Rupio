"use client";

import {
  type BaseError,
  useWriteContract,
  useWaitForTransactionReceipt,
  useAccount,
  useReadContract,
} from "wagmi";
import CollateralSafekeep from "@/abi/CollateralSafekeep.json";
import { parseEther } from "viem";
import { useState } from "react";

function LockETH() {
  const [popup, setPopup] = useState(false);
  const [txHash, setTxHash] = useState("");
  const { data: hash, isPending, writeContract, error } = useWriteContract();
  const { address } = useAccount();
  const { isLoading: isConfirming, isSuccess: isConfirmed } =
    useWaitForTransactionReceipt({
      hash,
    });

  const csk = {
    address: "0x2F15F0B2492694d65824C71aa41DDc848cb47614",
    abi: CollateralSafekeep,
  } as const;

  const { data: vault }: any = useReadContract({
    ...csk,
    functionName: "getVaultDetailsForTheUser",
    account: address,
  });
  const { data: maxWithdrawableCollateral }: any = useReadContract({
    ...csk,
    functionName: "getMaxWithdrawableCollateral",
    args: [address],
  });

  async function handleLockETH(e: React.FormEvent<HTMLFormElement>) {
    e.preventDefault();
    const formData = new FormData(e.target as HTMLFormElement);
    const ETHAmount = formData.get("ETHAmount") as string;
    const tx = await writeContract({
      ...csk,
      functionName: "createOrUpdateVault",
      account: address,
      value: parseEther(ETHAmount),
    });

    if (isConfirmed) {
      setTxHash(hash?.toString() || "");
      setPopup(true);
    }
  }

  async function handleWithdraw(e: React.FormEvent<HTMLFormElement>) {
    e.preventDefault();
    const formData = new FormData(e.target as HTMLFormElement);
    const ETHAmount = formData.get("ETHAmount") as string;
    const tx = await writeContract({
      ...csk,
      functionName: "withdrawFromVault",
      account: address,
      value: parseEther("0.001"),
      args: [parseEther(ETHAmount)],
    });
    // setTxHash(tx?.hash);
    // setPopup(true);
  }

  return (
    <div className="h-full flex flex-row justify-center items-center gap-8">
      <div className="flex flex-col items-center justify-center gap-8">
        <div className="flex flex-col border border-[var(--secondary)] rounded-xl p-6">
          <h2>Create a new vault or add ETH to an existing vault.</h2>
          <form className="mt-4 flex justify-center" onSubmit={handleLockETH}>
            <input
              className="p-2 border border-white rounded-xl bg-black"
              name="ETHAmount"
              placeholder="Amount ETH"
              required
            />
            <button
              disabled={isPending}
              type="submit"
              className="ml-4 p-2 bg-red-500 text-white rounded-md"
            >
              {isPending ? "Confirming..." : "Lock ETH"}
            </button>
          </form>
        </div>
        <div className="flex flex-col border border-[var(--secondary)] rounded-xl p-6">
          <h2 className="px-5">
            Withdraw underlying ETH from vault if no debt.
          </h2>
          <form className="mt-4 flex justify-center" onSubmit={handleWithdraw}>
            <input
              className="p-2 border border-white rounded-xl bg-black"
              name="ETHAmount"
              placeholder="Amount ETH"
              required
            />
            <button
              disabled={isPending}
              type="submit"
              className="ml-4 p-2 bg-red-500 text-white rounded-md"
            >
              {isPending ? "Confirming..." : "Withdraw"}
            </button>
          </form>
        </div>
      </div>
      <div className="flex flex-col justify-center items-center p-8 bg-transparent rounded-3xl text-white space-y-4 border border-white">
        <h3>Current Vault Status</h3>
        <div className="flex flex-row justify-between w-full">
          ETH Locked:
          <p>{(Number(vault?.balance.toString()) / 10 ** 18).toFixed(4)} ETH</p>
        </div>
        <div className="flex flex-row justify-between w-full">
          Max Withdrawable Collateral:
          <p>
            {(Number(maxWithdrawableCollateral?.toString()) / 10 ** 18).toFixed(
              4
            )}{" "}
            ETH
          </p>
        </div>
        <div className="flex flex-row justify-between w-full">
          Vault Health:
          <p>{Number(vault?.vaultHealth.toString()).toFixed(2)}</p>
        </div>
      </div>

      {popup && (
        <div className="fixed top-0 left-0 w-full h-full flex justify-center items-center bg-black bg-opacity-75">
          <div className="bg-white text-black p-4 rounded-lg">
            <h3>Transaction Receipt</h3>
            <p>Hash: {txHash}</p>
            <button
              onClick={() => setPopup(false)}
              className="mt-4 p-2 bg-red-500 text-white rounded-md"
            >
              Close
            </button>
          </div>
        </div>
      )}
    </div>
  );
}

export default LockETH;
