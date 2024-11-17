"use client";

import {
  type BaseError,
  useWriteContract,
  useWaitForTransactionReceipt,
} from "wagmi";
import CollateralSafekeep from "@/abi/CollateralSafekeep.json";
import { parseEther } from "viem";
function LockETH() {
  const { data: hash, isPending, writeContract, error } = useWriteContract();
  // const { address, isConnected } = useAccount();

  const csk = {
    address: "0x5F0f545F044628b8DF84F1933887eC6aa9E9449D",
    abi: CollateralSafekeep,
  } as const;

  async function submit(e: React.FormEvent<HTMLFormElement>) {
    e.preventDefault();
    const formData = new FormData(e.target as HTMLFormElement);
    const ETHAmount = formData.get("ETHAmount") as string;
    await writeContract({
      ...csk,
      functionName: "createOrUpdateVault",

      // account: address,
      // value: parseEther(ETHAmount),
      value: parseEther(ETHAmount),
    });
  }

  const { isLoading: isConfirming, isSuccess: isConfirmed } =
    useWaitForTransactionReceipt({
      hash,
    });

  return (
    <div className="h-full flex flex-row justify-center items-center gap-8">
      <div className="flex flex-col items-center justify-center gap-8">
        <div className="flex flex-col border border-[var(--secondary)] rounded-xl p-6">
          <h2>Create a new vault or add ETH to an existing vault.</h2>
          <form className="mt-4 flex justify-center " onSubmit={submit}>
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
            {isConfirming && <div>Waiting for confirmation...</div>}
            {isConfirmed && <div>Transaction confirmed.</div>}
            {error && (
              <div>
                Error: {(error as BaseError).shortMessage || error.message}
              </div>
            )}
            {hash && <div>Transaction Hash: {hash}</div>}
          </form>
        </div>
        <div className="flex flex-col border border-[var(--secondary)] rounded-xl p-6">
          <h2 className="px-5">
            Withdraw underlying ETH from vault if no debt.
          </h2>

          <form className="mt-4 flex justify-center " onSubmit={submit}>
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
            {isConfirming && <div>Waiting for confirmation...</div>}
            {isConfirmed && <div>Transaction confirmed.</div>}
            {error && (
              <div>
                Error: {(error as BaseError).shortMessage || error.message}
              </div>
            )}
            {hash && <div>Transaction Hash: {hash}</div>}
          </form>
        </div>
      </div>
      <div className="flex flex-col justify-center items-center p-8 bg-transparent rounded-3xl text-white space-y-4 border border-white ">
        <h3>Current Vault Status</h3>
        <div className="flex flex-row justify-between w-full">
          Indai:<p>{500}</p>
        </div>

        <div className="flex flex-row justify-between w-full">
          Max Mintable Indai:<p>{500}</p>
        </div>
        <div className="flex flex-row justify-between w-full  ">
          Max Withdrawable Collateral:<p className="ml-6">{500}</p>
        </div>
        <div className="flex flex-row justify-between w-full  ">
          Vault Health:<p className="ml-6">{500}</p>
        </div>
      </div>
    </div>
  );
}

export default LockETH;
