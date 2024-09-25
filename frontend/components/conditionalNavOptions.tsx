"use client";
import React, { useEffect, useState } from "react";
import { useAccount } from "wagmi";
import { Hamburger } from "./hamburgerog";
import Link from "next/link";
function ConditionalNavOptions() {
  const { isConnected } = useAccount();
  const [connectionStatus, setConnectionStatus] = useState(false);

  const [isSidebarOpen, setSidebarOpen] = useState(false);
  const toggleSidebar = () => {
    setSidebarOpen((prev) => !prev);
  };
  const closeSidebar = () => {
    setSidebarOpen(false);
  };

  useEffect(() => {
    setConnectionStatus(isConnected);
  }, [isConnected]);

  return (
    <div>
      {/* <Image src="/homepage.png" alt="logo" width={500} height={500} /> */}
      {!isSidebarOpen && (
        <Hamburger onClick={toggleSidebar} isInitiallyOpen={isSidebarOpen} />
      )}

      {isSidebarOpen ? (
        <div className=" bg-[var(--secondary)] fixed inset-0 h-screen w-screen">
          {connectionStatus ? (
            <div className="p-6">
              <div className="flex flex-row space-x-8 items-center ">
                <Hamburger
                  onClick={toggleSidebar}
                  isInitiallyOpen={isSidebarOpen}
                />
                <Link
                  href={""}
                  onClick={closeSidebar}
                  className="text-xl font-bold text-black"
                >
                  Indai Stablecoin.
                </Link>
              </div>
              <div className="text-black text-4xl  flex flex-col p-32 space-y-6">
                <Link onClick={closeSidebar} href="/Dashboard">
                  Dashboard {isConnected}
                </Link>
                <Link onClick={closeSidebar} href="/LockETH">
                  Create or Update Vault
                </Link>
                <Link onClick={closeSidebar} href="/MintINDAI">
                  Mint some Indai
                </Link>
              </div>
            </div>
          ) : (
            <div className="p-6">
              <Hamburger
                onClick={toggleSidebar}
                isInitiallyOpen={isSidebarOpen}
              />
              <h3 className="p-32  text-black">Connect Wallet to Dive Deep!</h3>
            </div>
          )}
        </div>
      ) : (
        <div></div>
      )}
    </div>
  );
}

export default ConditionalNavOptions;
