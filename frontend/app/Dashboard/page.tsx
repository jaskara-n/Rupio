"use client";
import { useAccount, useReadContracts } from "wagmi";
import { BaseError, useReadContract } from "wagmi";
import CollateralSafekeep from "@/abi/CollateralSafekeep.json";

function Dashboard() {
  const csk = {
    address: "0x5F0f545F044628b8DF84F1933887eC6aa9E9449D",
    abi: CollateralSafekeep,
  } as const;

  const { isConnected, address } = useAccount();
  // const { data, isLoading, isError, error } = useReadContract({
  //   abi: CollateralSafekeep,
  //   address: cskAddress,
  //   functionName: "getVaultDetailsForTheUser",
  //   account: address,
  // });

  const { data: balanceETH } = useReadContract({
    address: "0x5F0f545F044628b8DF84F1933887eC6aa9E9449D",
    abi: CollateralSafekeep,
    functionName: "getUserCollateralBalance",
    args: [address],
  });
  const { data: balanceINR } = useReadContract({
    ...csk,
    functionName: "getUserBalanceInINR",
    args: [address],
  });
  const { data: vaultHealth } = useReadContract({
    ...csk,
    functionName: "getVaultHealth",
    args: [address],
  });
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

  return (
    <div className="h-screen p-10 flex pt-20 flex-col space-y-2">
      <h1>Your Account Details</h1>
      <p>Locked ETH:{balanceETH?.toString()}</p>
      <p>Locked ETH in INR: {balanceINR?.toString()}</p>
      <p>Vault Health: {vaultHealth?.toString()}</p>
      <p>Max INDAI: {indai?.toString()}</p>
      <p>Max Collateral: {collateral?.toString()}</p>
    </div>
  );
}

export default Dashboard;
