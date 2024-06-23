import React, { useState } from 'react'
import Box from '@mui/material/Box';
import Modal from '@mui/material/Modal';
const style = {
    position: 'absolute',
    top: '50%',
    left: '50%',
    color: 'white',
    transform: 'translate(-50%, -50%)',
    width: 400,
    bgcolor: 'background.paper',
    border: '2px solid #000',
    boxShadow: 24,
    backgroundColor: '#1E1D34',
    p: 4,
};

const MakeOffer = () => {
    const [open, setOpen] = useState(false);
    const handleOpen = () => setOpen(true);
    const handleClose = () => setOpen(false);

  return (
    <div className="lg:w-[48%] md:w-[48%] w-[100%]">
    <button
        onClick={handleOpen}
         className="bg-[#E0BB83] text-[#2a2a2a] my-2 hover:bg-[#2a2a2a] hover:text-[white] hover:font-bold px-4 py-2  font-playfair w-[95%] mx-auto text-center text-[16px] font-bold rounded-lg"
    >Offer</button>
    <Modal
        open={open}
        onClose={handleClose}
        aria-labelledby="modal-modal-title"
        aria-describedby="modal-modal-description"
    >
        <Box sx={style}>
            <p className='lg:text-[24px] md:text-[24px] text-[18px] mb-4'>Make offer</p>
            <input type="text" placeholder='Request Id' className="rounded-lg w-[100%] p-4 bg-[#ffffff23] backdrop-blur-lg mb-4 outline-none" value='' disabled />
            <input type="text" placeholder='Interest' className="rounded-lg w-[100%] p-4 bg-[#ffffff23] backdrop-blur-lg mb-4 outline-none" value=''  />
            <input type="text" placeholder='Amount' className="rounded-lg w-[100%] p-4 bg-[#ffffff23] backdrop-blur-lg mb-4 outline-none" />
            <input type="date" placeholder='Return date' className="rounded-lg w-[100%] p-4 bg-[#ffffff23] backdrop-blur-lg mb-4 outline-none"  disabled />
            <input type="text" placeholder='Collateral currency address' className="rounded-lg w-[100%] p-4 bg-[#ffffff23] backdrop-blur-lg mb-4 outline-none" />
            <input type="text" placeholder='Request status' className="rounded-lg w-[100%] p-4 bg-[#ffffff23] backdrop-blur-lg mb-4 outline-none"  disabled />      
            <button
                className="bg-[#E0BB83] text-[#2a2a2a] my-2 hover:bg-[#2a2a2a] font-playfair hover:text-[white]  py-2 px-4 rounded-lg text-[16px] w-[100%] font-bold"
            >Make offer</button>
        </Box>
    </Modal>
</div>
  )
}

export default MakeOffer