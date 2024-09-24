import React from "react";
import Condition from "./conditionComponent";
function Navbar() {
  return (
    <div className="absolute w-full p-6 flex justify-between items-center">
      <h2>Indai Stablecoin.</h2>
      <div className="flex flex-row space-x-5 justify-center items-center">
        <w3m-button />
        <Condition />
      </div>
    </div>
  );
}

export default Navbar;
