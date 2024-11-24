"use client";
import React from "react";
import Image from "next/image";

function page() {
  return (
    <div className="h-full flex flex-row  items-center justify-evenly gap-6 mt-5">
      <div className="flex flex-col items-center h-full w-1/2  border-2 rounded-3xl p-6 border-[var(--secondary)] ">
        <h1>Borrow/Burn Rupio </h1>
        <Image src="/borrow.png" alt="borrow" width={320} height={300} />
        <p className="px-16">
          {" "}
          Borrow Rupio at the rate decided by the DAO using ETH OR burn Rupio to
          relieve underlying collateral.
        </p>
        <button
          className="primary mt-6"
          onClick={() => (window.location.href = "/MintRupio")}
        >
          Mint/Burn Rupio
        </button>
      </div>
      <div className="flex flex-col items-center h-full w-1/2 border-2 rounded-3xl p-6 border-[var(--secondary)]">
        <h1>Supply Rupio</h1>
        <Image src="/supply.png" alt="supply" width={330} height={300} />
        <p>Lock Rupio tokens inside the ISR contract and earn upto 7% ISR.</p>
        <button
          className="secondary mt-8"
          onClick={() => (window.location.href = "/SupplyRupio")}
        >
          Supply Rupio
        </button>
      </div>
    </div>
  );
}

export default page;
