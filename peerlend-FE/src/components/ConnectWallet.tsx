import React from "react";
import { useAccount } from "@starknet-react/core";
import ConnectModal from "./starknet/ConnectModal";

const ConnectWallet = () => {
  const { address } = useAccount();
  // const { disconnect } = useDisconnect();

  return (
    <div className="justify-between  flex flex-row px-4 p-2">
      {address ? (
        <div className="flex items-center text-[#E0BB83] rounded-md px-6 py-2">
          <p className="w-[30px] h-[30px] bg-gradient-to-r from-[#2e587d] via-[#2a2a2a] to-[#E0BB83]/30 rounded-full mr-4"></p>
          <p className="font-semibold">{`${address.slice(
            0,
            6,
          )}...${address.slice(-4)}`}</p>
          {/* <p
            onClick={() => disconnect()}
            className="cursor-pointer text-black/50"
          >
            Disconnect
          </p> */}
        </div>
      ) : (
        <ConnectModal />
      )}
    </div>
  );
}

export default ConnectWallet ;
