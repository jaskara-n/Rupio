"use client";
import React, { useState } from "react";
import { useSwitchChain } from "wagmi";

function CrossTransferWidget() {
  const { chains, switchChain } = useSwitchChain();
  const [rupioAmount, setRupioAmount] = useState("");
  const [recipientAddress, setRecipientAddress] = useState("");
  const [selectedFromChain, setSelectedFromChain] = useState<number | null>(
    null
  );
  const [selectedToChain, setSelectedToChain] = useState<number | null>(null);

  const handleInputChange = (event: React.ChangeEvent<HTMLInputElement>) => {
    setRupioAmount(event.target.value);
  };

  const handleAddressChange = (event: React.ChangeEvent<HTMLInputElement>) => {
    setRecipientAddress(event.target.value);
  };

  const handleFromChainChange = (
    event: React.ChangeEvent<HTMLSelectElement>
  ) => {
    const chainId = parseInt(event.target.value);
    setSelectedFromChain(chainId);
    const chain = chains.find((c) => c.id === chainId);
    if (chain) switchChain({ chainId: chain.id });
  };

  const handleToChainChange = (event: React.ChangeEvent<HTMLSelectElement>) => {
    setSelectedToChain(parseInt(event.target.value));
  };

  return (
    <div className="flex justify-center items-center h-full p-8">
      <div className="border border-yellow-300 rounded-xl pb-5 px-5 py-4 w-[500px] space-y-3">
        <h3>Cross-Transfer Rupio</h3>
        <div>
          <h3>From</h3>
          <div className="flex items-center bg-opacity-50 p-4 space-x-4 text-white border rounded-xl border-yellow-300">
            <input
              type="text"
              value={rupioAmount}
              onChange={handleInputChange}
              placeholder="0.00"
              className="bg-var[--background] placeholder-black rounded-xl text-black flex-grow focus:outline-none focus:ring-0 bg-[var(--secondary)] px-3 py-2"
            />
            <div className="whitespace-nowrap">{rupioAmount || "0"} RUP</div>
            <div className="relative w-40 overflow-hidden">
              <select
                className="w-full p-2 border border-dotted rounded-xl bg-transparent focus:outline-none focus:ring-0 appearance-none box-border"
                value={selectedFromChain || ""}
                onChange={handleFromChainChange}
              >
                <option value="">Select a chain</option>
                {chains.map((chain) => (
                  <option key={chain.id} value={chain.id}>
                    {chain.name}
                  </option>
                ))}
              </select>
              <span className="absolute inset-y-0 right-3 flex items-center pointer-events-none">
                ▼
              </span>
            </div>
          </div>
        </div>
        <div>
          <h3>To</h3>
          <div className="flex flex-row border border-white rounded-xl px-5 py-4  ">
            <input
              type="text"
              value={recipientAddress}
              onChange={handleAddressChange}
              placeholder="Recipient Address"
              className="bg-transparent placeholder-white rounded-xl text-white flex-grow focus:outline-none focus:ring-0 "
            />
            <div className="relative w-40 overflow-hidden mt-3">
              <select
                className="w-full p-2 border border-dotted rounded-xl bg-transparent focus:outline-none focus:ring-0 appearance-none box-border "
                value={selectedToChain || ""}
                onChange={handleToChainChange}
              >
                <option value="">Select a chain</option>
                {chains.map((chain) => (
                  <option key={chain.id} value={chain.id}>
                    {chain.name}
                  </option>
                ))}
              </select>
              <span className="absolute inset-y-0 right-3 flex items-center pointer-events-none">
                ▼
              </span>{" "}
            </div>
          </div>
        </div>
        <button className="secondary w-full "> Transact</button>
      </div>
    </div>
  );
}

export default CrossTransferWidget;
