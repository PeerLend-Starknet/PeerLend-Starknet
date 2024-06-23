import React, { useState, useMemo, useEffect } from 'react'
import Box from '@mui/material/Box';
import FormControl from '@mui/material/FormControl';
import Select from '@mui/material/Select';
import Modal from '@mui/material/Modal';
import InputLabel from '@mui/material/InputLabel';
import MenuItem from '@mui/material/MenuItem';


import { useAccount, useContract, useContractWrite } from '@starknet-react/core';

import peerlendAbi from "../constants/peerlendAbi.json";
import peerlend_address from '../constants';
import tokenList from '../constants/tokenList';
import { ethers } from 'ethers';

const style = {
  position: 'absolute',
  top: '50%',
  left: '50%',
  color: 'white',
  transform: 'translate(-50%, -50%)',
  width: 400,
  border: '2px solid #000',
  boxShadow: 24,
  backgroundColor: '#1E1D34',
  p: 4,
};

const CreateRequest = () => {
  const [open, setOpen] = useState(false);
  const handleOpen = () => setOpen(true);
  const handleClose = () => setOpen(false);

  const [tokenAddress, setTokenAddress] = useState<string>('');
  const [amount, setAmount] = useState<string>('0');
  const [interest, setInterest] = useState<string>('');
  const [returnDate, setReturnDate] = useState("");

  const { address } = useAccount();

  const { contract } = useContract({ abi: peerlendAbi, address: peerlend_address });

  const calls = useMemo(() => {

    if (!contract || !address || !tokenAddress || !amount || !interest || !returnDate) return [];

    const _returnDate = new Date(returnDate).getTime() / 1000;
    return contract.populateTransaction["create_request"]!(ethers.parseEther(amount || "0")  , interest, _returnDate, tokenAddress);
  }, [contract, tokenAddress, amount, interest, returnDate]);

  const { writeAsync } = useContractWrite({ calls });

  return (
    <div>
      <div>
        <button className="bg-[#E0BB83] text-[#2A2A2A] py-2 px-4 rounded-lg  font-bold font-playfair text-[18px] w-[100%] my-2 hover:bg-[#2a2a2a] hover:text-[white] hover:font-bold" onClick={handleOpen}>Create Request</button>
        <Modal
          open={open}
          onClose={handleClose}
          aria-labelledby="modal-modal-title"
          aria-describedby="modal-modal-description"
        >
          <Box sx={style}>
            <p id="modal-modal-title" className="text-[#E0BB83] font-playfair font-bold text-[24px] text-red-700 text-center">Ensure Enough collateral has been added before requesting for loan.</p>
            <input
              value={amount}
              onChange={(e) => {setAmount(e.target.value) }}
              type="text" placeholder='Amount' className="rounded-lg w-[100%] p-4 bg-[#ffffff23] backdrop-blur-lg mb-4 outline-none" />
            <input
              value={interest}
              onChange={(e) => { setInterest(e.target.value) }}
              type="text" placeholder='Interest' className="rounded-lg w-[100%] p-4 bg-[#ffffff23] backdrop-blur-lg mb-4 outline-none" />
            <input
              value={returnDate}
              onChange={(e) => { setReturnDate(e.target.value) }}
              type="Date" placeholder='Return date' className="rounded-lg w-[100%] p-4 bg-[#ffffff23] backdrop-blur-lg mb-4 outline-none" />
            <FormControl fullWidth>
              <InputLabel id="demo-simple-select-label">Loan Currency</InputLabel>
              <Select
                labelId="demo-simple-select-label"
                id="demo-simple-select"
                value={tokenAddress}
                label="loan currency"
                onChange={(e) => { setTokenAddress(e.target.value) }}
                sx={{ backgroundColor: "#ffffff23", outline: "none", color: "gray", marginBottom: "20px" }}
              >
                {Object.keys(tokenList).map((address: string) => {
                  const token = tokenList[address];
                  return (<MenuItem key={token.address} value={token.address}>{token.symbol}</MenuItem>)
                })}
              </Select>
            </FormControl>
            <button
              onClick={() => { writeAsync() }}
              className="bg-[#E0BB83] text-[#2A2A2A] py-2 px-4 rounded-lg  font-bold font-playfair text-[18px] w-[100%] my-4">Create &rarr;</button>
          </Box>
        </Modal>
      </div>
    </div>
  )
}

export default CreateRequest