import React from "react";
import ConditionalNavOptions from "./conditionalNavOptions";
import Link from "next/link";
function Navbar() {
  return (
    <div className=" absolute w-full p-6 flex justify-between items-center">
      <div className="flex flex-row space-x-8 justify-between items-center">
        {" "}
        <ConditionalNavOptions />
        <Link href={"/"} className="text-xl font-bold">
          RupioDao.
        </Link>
      </div>

      {/* <div className="flex flex-row space-x-5 justify-center items-center"> */}

      <w3m-button />
    </div>
    // </div>
  );
}

export default Navbar;
