"use client";

import {
  type BaseError,
  useWriteContract,
  useWaitForTransactionReceipt,
} from "wagmi";
import CollateralSafekeep from "@/abi/CollateralSafekeep.json";
function LockETH() {
  const { data: hash, isPending, writeContract, error } = useWriteContract();

  const csk = {
    address: "0x5F0f545F044628b8DF84F1933887eC6aa9E9449D",
    abi: CollateralSafekeep,
  } as const;

  async function submit(e: React.FormEvent<HTMLFormElement>) {
    e.preventDefault();
    const formData = new FormData(e.target as HTMLFormElement);
    const INDAIAmount = formData.get("INDAIAmount") as string;
    await writeContract({
      ...csk,
      functionName: "mintIndai",

      // account: address,
      // value: parseEther(ETHAmount),
      args: [BigInt(INDAIAmount)],
    });
  }

  const { isLoading: isConfirming, isSuccess: isConfirmed } =
    useWaitForTransactionReceipt({
      hash,
    });

  return (
    <div className="h-full p-10 flex flex-col items-center justify-center">
      <div className="flex flex-row gap-6">
        <div className="bg-yellow-300 bg-opacity-10 px-8 py-6 rounded-3xl space-y-4 border-2 border-[var(--secondary)]">
          <h4>Mint Indai</h4>
          <p className="font-bold">Already have ETH locked? </p>
          <div className="px-3 py-1 bg-white text-black rounded-md flex justify-between border-4 border-black">
            <p>Max Mintable Indai</p>
            <p className="font-bold">{400} INDAI</p>
          </div>
          <p className="bg-transparent px-3 py-2 rounded-lg border border-[var(--secondary)]">
            FYI: You need to have some ETH as <br /> collateral beofore you can
            mint Indai.
          </p>
          <form className="mt-4 " onSubmit={submit}>
            <input
              className="p-2 border border-white rounded-xl bg-transparent"
              name="INDAIAmount"
              placeholder="Amount"
              required
            />
            <button
              disabled={isPending}
              type="submit"
              className="ml-4 p-2 bg-red-800 text-white rounded-md"
            >
              {isPending ? "Confirming..." : "Mint Indai"}
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

          <p className="font-bold">Else lock some ETH today!</p>
          <button
            className="secondary py-2 px-4 mt-2"
            onClick={() => (window.location.href = "/LockETH")}
          >
            Lock ETH
          </button>
        </div>
        <div className="bg-yellow-300 bg-opacity-10 px-8 py-6 rounded-3xl space-y-4 border-solid border-2 border-[var(--secondary)] ">
          <h4>Burn Indai</h4>
          <p className="font-bold">Have underlying ETH debt?</p>
          <div className="px-3 py-1 bg-[var(--secondary)] border-4 border-black text-black rounded-md flex justify-between">
            <p className="">Indai Tokens Issued</p>
            <p className="font-bold">{400} INDAI</p>
          </div>
          <p className="bg-transparent border border-[var(--secondary)] px-3 py-2  rounded-lg">
            Cover your debt by burning Indai to
            <br /> relieve ETH collateral.
            <br /> FYI: You need to have some Indai
            <br /> minted before you can burn Indai.
          </p>
          <form className="py-4" onSubmit={submit}>
            <input
              className="p-2 border border-white rounded-xl bg-transparent"
              name="INDAIAmount"
              placeholder="Amount in INDAI"
              required
            />
            <button
              disabled={isPending}
              type="submit"
              className="ml-4 p-2 bg-red-800 text-white rounded-md"
            >
              {isPending ? "Confirming..." : "Burn Indai"}
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
    </div>
  );
}

export default LockETH;
