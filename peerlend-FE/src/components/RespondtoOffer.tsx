import React, { useState } from 'react'
import Box from '@mui/material/Box';
import Modal from '@mui/material/Modal';
const style = {
    position: 'absolute',
    top: '50%',
    left: '50%',
    color: 'white',
    transform: 'translate(-50%, -50%)',
    width: 500,
    bgcolor: 'background.paper',
    border: '2px solid #000',
    boxShadow: 24,
    backgroundColor: '#1E1D34',
    p: 3,
};

const RespondtoOffer = () => {
    const [open, setOpen] = useState(false);
    const handleOpen = () => setOpen(true);
    const handleClose = () => setOpen(false);

  return (
    <div>
    <button
        onClick={handleOpen}
        className="bg-[#E0BB83] text-[#2a2a2a] my-2 hover:bg-[#2a2a2a] hover:text-[white] hover:font-bold px-4 py-2  font-playfair w-[95%] mx-auto text-center text-[16px] font-bold rounded-lg"
    >Respond</button>
    <Modal
        open={open}
        onClose={handleClose}
        aria-labelledby="modal-modal-title"
        aria-describedby="modal-modal-description"
    >
        <Box sx={style}>
            <input type="text" placeholder='Request Id' className="rounded-lg w-[100%] p-4 bg-[#ffffff23] backdrop-blur-lg mb-4 outline-none" />
            <input type="text" placeholder='Offer Id' className="rounded-lg w-[100%] p-4 bg-[#ffffff23] backdrop-blur-lg mb-4 outline-none"  />
            <p className='lg:text-[24px] md:text-[24px] text-[18px] mb-4'>Offer </p>
            <p className='lg:text-[20px] md:text-[20px] text-[15px] mb-4'>Total offers: </p>
            <p>Lender: </p>
            <p>Amount: </p>
            <p>Interest: </p>

            <button
               className="bg-[#E0BB83] text-[#2a2a2a] my-2 hover:bg-[#2a2a2a] font-playfair hover:text-[white]  py-2 px-4 rounded-lg text-[16px] w-[100%] font-bold">Accept</button>
            <button
               className="bg-[#E0BB83] text-[#2a2a2a] my-2 hover:bg-[#2a2a2a] font-playfair hover:text-[white]  py-2 px-4 rounded-lg text-[16px] w-[100%] font-bold">Reject</button>
        </Box>
    </Modal>
</div>
  )
}

export default RespondtoOffer