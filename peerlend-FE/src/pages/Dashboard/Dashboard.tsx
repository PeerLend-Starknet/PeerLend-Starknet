import React from 'react'
// import Stack from '@mui/material/Stack';
// import { Gauge, gaugeClasses  } from '@mui/x-charts/Gauge';
import DepositCollateral from '../../components/DepositCollateral';
import { RiCompassDiscoverFill } from "react-icons/ri";
import { PieChart } from '@mui/x-charts/PieChart';
import RecentData from '../../components/RecentData';

const Dashboard = () => {
  return (
   <main>
    <div className=''>
    <h2 className="lg:text-[24px] md:text-[24px] text-[20px] text-[#E0BB83] font-playfair font-bold mb-4 items-center">Welcome</h2>
    </div>
    <section className='flex flex-col lg:flex-row md:flex-row justify-between mb-6'>
        <div className='bg-gradient-to-r from-[#E0BB83]/40 via-[#2a2a2a] to-[#E0BB83]/30 p-6 rounded-md lg:w-[60%] md:w-[60%] w-[100%] mb-4 shadow-lg'>
        <h3 className='text-[20px] font-playfair font-[700] my-4'>Get Started</h3>
        <div className='flex justify-between w-[100%'>
        <p className='lg:w-[55%] md:w-[55%] w-[100%] font-[400]'>As a borrower, get started by adding your collateral to secure your loan. .</p>
        <div className='ml-auto w-[35%] mt-auto'>
        <DepositCollateral />
        </div>
        </div>
        </div>
        <div className='bg-[#2a2a2a] p-6 rounded-md lg:w-[38%] md:w-[38%] w-[100%] mb-4 shadow-lg border border-[#E0BB83]/30'>
        <h3 className='text-[20px] font-playfair font-[700] my-4'>Explore Lending Opportunities</h3>
        <div className='flex justify-between w-[100%'>
        <p className='font-[400] mb-4 lg:w-[75%] md:w-[75%] w-[100%] '>If you&apos;re looking to lend, explore the request page to find lending opportunities</p>
        <div className='w-[15%] text-4xl'>
        <button><RiCompassDiscoverFill className='text-[#E0BB83] text-[40px] hover:bg-[#2a2a2a] hover:text-[white]'/></button>
        </div>
        </div>
        </div>
    </section>
     <section>
     <h3 className='text-[20px] font-playfair font-[700] my-4 text-[#E0BB83]'>General Overview</h3>
        <div className="flex lg:flex-row md:flex-row flex-col justify-between">
        <div className="bg-[#e0bb8314] shadow-lg border border-[#E0BB83]/30 p-6 rounded-lg w-[100%] lg:w-[19%] md:w-[19%] text-center">
          <h3>Offer</h3>
          <p className="lg:text-[28px] md:text-[28px] text-[20px] font-bold">4</p>
        </div>
         <div className="bg-[#e0bb8314] shadow-lg border border-[#E0BB83]/30 p-6 rounded-lg w-[100%] lg:w-[19%] md:w-[19%] text-center">
          <h3>Loan Amount</h3>
          <p className="lg:text-[28px] md:text-[28px] text-[20px] font-bold"><span>&#36;</span>4000</p>
        </div>
         <div className="bg-[#e0bb8314] shadow-lg border border-[#E0BB83]/30 p-6 rounded-lg w-[100%] lg:w-[19%] md:w-[19%] text-center">
          <h3>Collateral</h3>
          <p className="lg:text-[28px] md:text-[28px] text-[20px] font-bold"><span>&#36;</span>4500</p>
        </div>
         <div className="bg-[#e0bb8314] shadow-lg border border-[#E0BB83]/30 p-6 rounded-lg w-[100%] lg:w-[19%] md:w-[19%] text-center">
          <h3>Total Requests</h3>
          <p className="lg:text-[28px] md:text-[28px] text-[20px] font-bold">5</p>
        </div>
         <div className="bg-[#e0bb8314] shadow-lg border border-[#E0BB83]/30 p-6 rounded-lg w-[100%] lg:w-[19%] md:w-[19%] text-center">
          <h3>Total Offer</h3>
          <p className="lg:text-[28px] md:text-[28px] text-[20px] font-bold">5</p>
        </div>
        </div>
      </section>
      <section className='my-8'>
     <h3 className='text-[20px] font-playfair font-[700] my-4 text-[#E0BB83]'>Recent Activity</h3>
     <div className='flex justify-between'>
        <div className='w-[60%] p-4'>
            <RecentData />
        </div>
        <div className='text-white'>
        <PieChart sx={{ color: 'white'}}
            series={[
                {
                data: [
                    { id: 0, value: 10, label: 'Loan' },
                    { id: 1, value: 15, label: 'Request' },
                    { id: 2, value: 20, label: 'Offers' },
                ],
                },
            ]}
        width={400}
        height={200}
        />
        </div>
        </div>
      </section>
   
   </main>
  )
}

export default Dashboard

{/* <Stack direction={{ xs: 'column', md: 'row' }} spacing={{ xs: 1, md: 3 }}>
<Gauge width={100} height={100} value={60} sx={() => ({
    [`& .${gaugeClasses.valueText}`]: {
    fontSize: 28,
    fill: '#FFFFFF',
    },
    [`& .${gaugeClasses.valueArc}`]: {
    fill: '#E0BB83',
    }
})}
/>
</Stack> */}