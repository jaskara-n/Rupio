"use client";
import { useAccount } from "wagmi";
import { useReadContract } from "wagmi";
// import { cskContract } from "@/constants/index";
import CollateralSafekeep from "@/abi/CollateralSafekeep.json";

function Dashboard() {
  const { address } = useAccount();

  const csk = {
    address: "0x5f0f545f044628b8df84f1933887ec6aa9e9449d",
    abi: CollateralSafekeep,
  } as const;
  // const csk = {
  //   address: cskContract.address || "",
  //   abi: cskContract.abi,
  // } as const;

  const { data: indai } = useReadContract({
    ...csk,
    functionName: "getMaxMintableIndai",
    args: [address],
  });

  const { data: collateral } = useReadContract({
    ...csk,
    functionName: "getMaxWithdrawableCollateral",
    args: [address],
  });

  const { data: vault }: any = useReadContract({
    ...csk,
    functionName: "getVaultDetailsForTheUser",
    account: address,
  });

  return (
    <div className="h-full  p-8 ">
      <div className="flex-col flex h-full justify-center items-center ">
        <div className="bg-yellow-300 bg-opacity-10 rounded-3xl px-6 py-4 border border-[var(--secondary)]">
          <h1 className="mb-2">Dashboard.</h1>
          <div className="space-y-4 ]">
            <div className="flex flex-row justify-between">
              <p>Vault Id: </p> {Number(vault?.vaultId.toString())}
            </div>
            <div className="flex flex-row justify-between">
              <p>Locked ETH:</p>
              {(Number(vault?.balance.toString()) / 10 ** 18).toFixed(4)} ETH
            </div>

            <div className="flex flex-row justify-between">
              <p>Locked ETH in INR: </p>
              {(Number(vault?.balanceInINR.toString()) / 10 ** 8).toFixed(
                2
              )}{" "}
              INR
            </div>
            <div className="flex flex-row justify-between">
              <p> Indai Issued:</p>
              {Number(vault?.indaiIssued.toString())} IND
            </div>
            <div className="flex flex-row justify-between">
              <p>Vault Health:</p>{" "}
              {Number(vault?.vaultHealth.toString()).toFixed(2)}
            </div>
            <div className="flex flex-row justify-between">
              <p> Max Mintable INDAI:</p> {indai?.toString()} IND
            </div>
            <div className="flex flex-row justify-between">
              <p className="mr-8"> Max Withdrawable Collateral:</p>
              {(Number(collateral?.toString()) / 10 ** 18).toFixed(4)} ETH
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}

export default Dashboard;
