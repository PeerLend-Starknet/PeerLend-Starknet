import React, { useState } from 'react'
import Box from '@mui/material/Box';
import FormControl from '@mui/material/FormControl';
import Select from '@mui/material/Select';
import Modal from '@mui/material/Modal';
import InputLabel from '@mui/material/InputLabel';
import MenuItem from '@mui/material/MenuItem';
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
            <input type="text" placeholder='Amount' className="rounded-lg w-[100%] p-4 bg-[#ffffff23] backdrop-blur-lg mb-4 outline-none" />
            <input type="text" placeholder='Interest' className="rounded-lg w-[100%] p-4 bg-[#ffffff23] backdrop-blur-lg mb-4 outline-none" />
            <input type="Date" placeholder='Return date' className="rounded-lg w-[100%] p-4 bg-[#ffffff23] backdrop-blur-lg mb-4 outline-none" />
            <FormControl fullWidth>
              <InputLabel id="demo-simple-select-label">Loan Currency</InputLabel>
              <Select
                labelId="demo-simple-select-label"
                id="demo-simple-select"
                value=''
                label="loan currency"
                sx={{ backgroundColor: "#ffffff23", outline: "none", color: "gray", marginBottom: "20px" }}
              >
            <MenuItem >Link</MenuItem>
              </Select>
            </FormControl>
            <button className="bg-[#E0BB83] text-[#2A2A2A] py-2 px-4 rounded-lg  font-bold font-playfair text-[18px] w-[100%] my-4">Create &rarr;</button>
          </Box>
        </Modal>
      </div>
    </div>
  )
}

export default CreateRequest