"use client";
import React, { useEffect, useState } from "react";
import { useAccount } from "wagmi";
import { useRouter } from "next/navigation";
function Condition() {
  const { isConnected } = useAccount();
  const [connectionStatus, setConnectionStatus] = useState(false);

  useEffect(() => {
    setConnectionStatus(isConnected);
  }, [isConnected]);
  const { push } = useRouter();

  return (
    <div className="">
      {/* <Image src="/homepage.png" alt="logo" width={500} height={500} /> */}
      {connectionStatus ? (
        <div className="space-x-5">
          <button onClick={() => push("/MintINDAI")}>Mint INDAI</button>
          <button onClick={() => push("/LockETH")}>Lock ETH</button>
          <button onClick={() => push("/Dashboard")}>Dashboard</button>
        </div>
      ) : (
        <h1></h1>
      )}
    </div>
  );
}

export default Condition;
