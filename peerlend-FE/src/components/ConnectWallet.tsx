import React from "react";
import { useAccount, useDisconnect } from "@starknet-react/core";
import ConnectModal from "./starknet/ConnectModal";

const ConnectWallet = () => {
  const { address } = useAccount();
  const { disconnect } = useDisconnect();

  return (
    <div className="justify-between  flex flex-row px-4 p-2">
      {address ? (
        <div className="flex flex-col items-end bg-zinc-100 rounded-md px-6 py-2">
          <p className="font-semibold">{`${address.slice(
            0,
            6,
          )}...${address.slice(-4)}`}</p>
          <p
            onClick={() => disconnect()}
            className="cursor-pointer text-black/50"
          >
            Disconnect
          </p>
        </div>
      ) : (
        <ConnectModal />
      )}
    </div>
  );
}

export default ConnectWallet ;
