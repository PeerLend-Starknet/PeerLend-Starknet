import React from 'react'
import ConnectWallet from '../../components/ConnectWallet'
import { Link } from 'react-router-dom'

const Explore = () => {
  return (
    <main>
           <div className='flex justify-between items-center mb-6'>
        <h2 className="lg:text-[24px] md:text-[24px] text-[20px] text-[#E0BB83] font-playfair font-bold mb-4 items-center">Explore</h2>
        <ConnectWallet />
        </div>
        <section className='flex flex-col lg:flex-row md:flex-row justify-between mb-6'>
        <div className='bg-gradient-to-r from-[#E0BB83]/40 via-[#2a2a2a] to-[#E0BB83]/30 lg:p-6 md:p-6 p-4 rounded-md lg:w-[67%] md:w-[67%] w-[100%] mb-4 shadow-lg'>
        <h3 className='text-[20px] font-playfair font-[700] my-4'>Explore All Active Requests</h3>
        <div className='w-[100%'>
        <p className='w-[100%] font-[400]'>Browse through diverse requests, evaluate the details, and as a lender choose the ones you want to fund. It&apos;s an easy way to find and support borrowers on PeerLend..</p>

        </div>
        </div>
        <div className="bg-[#e0bb8314] shadow-lg border border-[#E0BB83]/30 p-6 rounded-lg w-[100%] lg:w-[15%] md:w-[15%] text-center flex mb-4 flex-col items-center justify-center">
          <h3>Borrowers</h3>
          <p className="lg:text-[28px] md:text-[28px] text-[20px] font-bold">11</p>
        </div>
        <div className="bg-[#e0bb8314] shadow-lg border border-[#E0BB83]/30 p-6 rounded-lg w-[100%] lg:w-[15%] md:w-[15%] text-center flex mb-4 flex-col items-center justify-center">
          <h3>Lenders</h3>
          <p className="lg:text-[28px] md:text-[28px] text-[20px] font-bold">4</p>
        </div>
        </section>
        <section>
      <h3 className='text-[20px] font-playfair font-[700] my-4 text-[#E0BB83]'>All Active Requests</h3>
        <div className="flex justify-between flex-wrap">     
            <div className="w-[100%] lg:w-[31%] md:w-[31%] rounded-lg border border-[#E0BB83]/40  p-4 mt-6">
            <Link to={`/dashboard/explore/id`}>
                <img src='https://z-p3-scontent.fiba1-2.fna.fbcdn.net/o1/v/t0/f1/m247/2850021285355695016_2501028907_22-06-2024-04-34-56.jpeg?_nc_ht=z-p3-scontent.fiba1-2.fna.fbcdn.net&_nc_cat=102&ccb=9-4&oh=00_AYC1Z9Nt9gCWm8sHZ_yH-6sZYlv-w5ySnuMEa1F81h25RQ&oe=66794051&_nc_sid=5b3566' alt="" className="w-[100%] rounded-lg h-[200px] object-cover object-center mb-4" />
                <p>Amount: 100</p>
                <p>Rate: <span>&#37;</span></p>
                <p>Repayment: </p>
                <p>Return date: </p>
            </Link>
            </div>
        </div>
      </section>
    </main>
  )
}

export default Explore