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
    <div className="h-screen p-10 flex flex-col items-center justify-center">
      <h2>Create a new vault or add ETH to an existing vault.</h2>

      <form className="mt-4 " onSubmit={submit}>
        <input
          className="p-2 border border-white rounded-xl bg-black"
          name="ETHAmount"
          placeholder="Eg: 0.01, 123, etc"
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
          <div>Error: {(error as BaseError).shortMessage || error.message}</div>
        )}
        {hash && <div>Transaction Hash: {hash}</div>}
      </form>
    </div>
  );
}

export default LockETH;
