"use client";
import { useAccount } from "wagmi";
import { useReadContract } from "wagmi";
// import { cskContract } from "@/constants/index";
import CollateralSafekeep from "@/abi/CollateralSafekeep.json";

function Dashboard() {
  const { address } = useAccount();

  const csk = {
    address: "0x2F15F0B2492694d65824C71aa41DDc848cb47614",
    abi: CollateralSafekeep,
  } as const;
  // const csk = {
  //   address: cskContract.address || "",
  //   abi: cskContract.abi,
  // } as const;

  const { data: indai } = useReadContract({
    ...csk,
    functionName: "getMaxMintableRupio",
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
        <div className="bg-gray-400 bg-opacity-10 space-y-3 rounded-3xl px-8 py-5 border border-[var(--secondary)]">
          <h1 className="mb-2">Dashboard.</h1>
          <hr />
          <div className="space-y-4 ]">
            <div className="flex flex-row justify-between">
              <p>Vault Id: </p> {Number(vault?.vaultId.toString())}
            </div>
            <hr />
            <div className="flex flex-row justify-between">
              <p>Locked ETH:</p>
              {(Number(vault?.balance.toString()) / 10 ** 18).toFixed(4)} ETH
            </div>
            <hr />
            <div className="flex flex-row justify-between">
              <p>Locked ETH in INR: </p>
              {(Number(vault?.balanceInINR.toString()) / 10 ** 8).toFixed(
                2
              )}{" "}
              INR
            </div>{" "}
            <hr />
            <div className="flex flex-row justify-between">
              <p> Rupio Issued:</p>
              {(Number(vault?.rupioIssued.toString()) / 10 ** 8).toFixed(2)} RUP
            </div>{" "}
            <hr />
            <div className="flex flex-row justify-between">
              <p>Vault Health:</p>{" "}
              {Number(vault?.vaultHealth.toString()).toFixed(2)}
            </div>{" "}
            <hr />
            <div className="flex flex-row justify-between">
              <p> Max Mintable Rupio:</p>{" "}
              {(Number(indai?.toString()) / 10 ** 8).toFixed(2)} RUP
            </div>{" "}
            <hr />
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
