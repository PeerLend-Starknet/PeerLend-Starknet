import React, { useState } from 'react'
import Box from "@mui/material/Box";
import FormControl from "@mui/material/FormControl";
import Select from "@mui/material/Select";
import Modal from "@mui/material/Modal";
import InputLabel from "@mui/material/InputLabel";
import MenuItem from "@mui/material/MenuItem";
const style = {
    position: "absolute",
    top: "50%",
    left: "50%",
    color: "white",
    transform: "translate(-50%, -50%)",
    width: 400,
    border: "2px solid #000",
    boxShadow: 24,
    backgroundColor: "#1E1D34",
    p: 4,
  };

const DepositCollateral = () => {
    const [open, setOpen] = useState(false);
  const handleOpen = () => setOpen(true);
  const handleClose = () => setOpen(false);

  return (
    <div className="w-[100%]">
    <button
        onClick={handleOpen}
        className="bg-[#E0BB83] text-[#2a2a2a] my-2 hover:bg-[#2a2a2a] hover:text-[white] hover:font-bold px-4 py-2  font-playfair w-[95%] mx-auto text-center text-[16px] font-bold rounded-lg"
    >Deposit</button>
    <Modal
        open={open}
        onClose={handleClose}
        aria-labelledby="modal-modal-title"
        aria-describedby="modal-modal-description"
    >
        <Box sx={style}>
            <p className='lg:text-[20px] md:text-[20px] text-[18px] mb-4 font-playfair'>Deposit collateral</p>
            <FormControl fullWidth>
                <InputLabel id="demo-simple-select-label" sx={{ color: "white" }}>Token Address</InputLabel>
                <Select
                    labelId="demo-simple-select-label"
                    id="demo-simple-select"
                    value=''
                    label="Token address"
                    sx={{ backgroundColor: "#ffffff23", outline: "none", color: "gray", marginBottom: "20px" }}
                >
                    <MenuItem>Link</MenuItem>
                </Select>
            </FormControl>
            <input
            type="text"
            placeholder="amount of collateral"
            className="rounded-lg w-[100%] p-4 bg-[#ffffff23] backdrop-blur-lg mb-4 outline-none"
          />
          <button
            className="bg-[#E0BB83] text-[#2a2a2a] font-playfair font-bold py-2 px-4 rounded-lg lg:text-[18px] md:text-[18px] text-[16px] w-[100%] my-4"
          >Deposit</button>
        </Box>
    </Modal>
    </div>
  )
}

export default DepositCollateral