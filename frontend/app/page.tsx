"use client";
import React from "react";
import Image from "next/image";
import { useAccount } from "wagmi";

function Condition() {
  const { address, isConnected } = useAccount();

  return (
    <div className="h-screen p-10 flex justify-center items-center">
      {/* <Image src="/homepage.png" alt="logo" width={500} height={500} /> */}
      <h1 className="">
        Onboarding next indian crypto market to have their own stablecoin.
      </h1>
    </div>
  );
}

export default Condition;
