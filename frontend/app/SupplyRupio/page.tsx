"use client";
import React, { useState } from "react";

function Page() {
  const [amount, setAmount] = useState("");

  const handleLock = () => {
    if (!amount) {
      alert("Please enter an amount to lock.");
      return;
    }
    alert(`Locked ${amount} RUP successfully!`);
    setAmount(""); // Reset input after locking
  };

  return (
    <div className="h-screen p-8 space-y-4 w-[700px]">
      <h1>Get Returns on Holding Rupio</h1>
      <h2>Fixed Lock Period</h2>
      <div className="flex flex-row justify-between">
        <h2>Amount Locked</h2>
        <p>300 RUP</p>
      </div>

      <div className="flex flex-row justify-between">
        <h2>Returns Accumulated</h2>
        <p>300 RUP</p>
      </div>

      <div className="space-y-2 flex flex-row justify-between">
        <input
          type="number"
          placeholder="Enter Amount to Lock"
          value={amount}
          onChange={(e) => setAmount(e.target.value)}
          className="w-full p-2  bg-transparent  border rounded-xl mr-3"
        />
        <button onClick={handleLock} className="secondary whitespace-nowrap">
          Lock Amount
        </button>
      </div>
    </div>
  );
}

export default Page;
