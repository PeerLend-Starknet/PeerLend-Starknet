import React from 'react';
import { Gauge, gaugeClasses } from '@mui/x-charts/Gauge';
import ConnectWallet from '../../components/ConnectWallet';
import CreateRequest from '../../components/CreateRequest';
import peerlendAbi from "../../constants/peerlendAbi.json";
import peerlend_address from '../../constants';
//import { useContractRead } from '@starknet-react/core';
import { useAccount } from '@starknet-react/core';
import { Link } from 'react-router-dom';
import useReadContract from '../../components/useReadContract';

type Result = Array<{
  request_id: bigint;
  borrower: bigint;
  amount: bigint;
  interest_rate: bigint;
  total_repayment: bigint;
  return_date: bigint;
}>;

const Portfolio = () => {
  // const { data, isLoading } = useContractRead({
  //   abi: peerlendAbi,
  //   address: peerlend_address,
  //   functionName: "get_all_requests",
  //   args: []
  // });


  const res = useReadContract(peerlendAbi, peerlend_address, "get_all_requests", []);

  const { data: data, isLoading: isLoading } = res;
  console.log(data, "data");

  const { address } = useAccount();

  // Parsing data to match the expected type
  const parseData = (data: any): Result | undefined => {
    if (!data) return undefined;
    return data.map((item: any) => ({
      request_id: BigInt(item.request_id),
      borrower: BigInt(item.borrower),
      amount: BigInt(item.amount),
      interest_rate: BigInt(item.interest_rate),
      total_repayment: BigInt(item.total_repayment),
      return_date: BigInt(item.return_date)
    }));
  };

  const portfolioRes: Result | undefined = parseData(data);

  return (
    <div>
      {address ? (
        <main>
          <div className='flex justify-between items-center mb-6'>
            <h2 className="lg:text-[24px] md:text-[24px] text-[20px] text-[#E0BB83] font-playfair font-bold mb-4 items-center">Portfolio</h2>
            <ConnectWallet />
          </div>
          <section className='flex flex-col lg:flex-row md:flex-row justify-between mb-6'>
            <div className='bg-gradient-to-r from-[#E0BB83]/40 via-[#2a2a2a] to-[#E0BB83]/30 lg:p-6 md:p-6 p-4 rounded-md lg:w-[67%] md:w-[67%] w-[100%] mb-4 shadow-lg'>
              <h3 className='text-[20px] font-playfair font-[700] my-4'>Get a Loan</h3>
              <div className='flex lg:flex-row md:flex-row flex-col justify-between w-[100%'>
                <p className='lg:w-[55%] md:w-[55%] w-[100%] font-[400]'>Create a loan request detailing your desired amount and terms. Your request will be visible to lenders, who can then choose to fund your loan.</p>
                <div className='ml-auto lg:w-[35%] md:w-[35%] w-[100%] mt-auto'>
                  <CreateRequest />
                </div>
              </div>
            </div>
            <div className='bg-[#2a2a2a] lg:p-6 md:p-6 p-4 rounded-md lg:w-[30%] md:w-[30%] w-[100%] mb-4 shadow-lg border border-[#E0BB83]/30 flex'>
              <h3 className='text-[20px] font-playfair font-[700] my-4'>Credit <br /> Score</h3>
              <Gauge width={150} height={150} value={60} sx={() => ({
                [`& .${gaugeClasses.valueText}`]: {
                  fontSize: 28,
                  color: '#FFFFFF',
                },
                [`& .${gaugeClasses.valueArc}`]: {
                  fill: '#E0BB83',
                }
              })}
              />
            </div>
          </section>
          <section>
            <h3 className='text-[20px] font-playfair font-[700] my-4 text-[#E0BB83]'>Overview</h3>
            <div className="flex lg:flex-row md:flex-row flex-col justify-between">
              <div className="bg-[#e0bb8314] shadow-lg border border-[#E0BB83]/30 p-6 rounded-lg w-[100%] lg:w-[19%] md:w-[19%] text-center mb-4">
                <h3>My Offers</h3>
                <p className="lg:text-[28px] md:text-[28px] text-[20px] font-bold">4</p>
              </div>
              <div className="bg-[#e0bb8314] shadow-lg border border-[#E0BB83]/30 p-6 rounded-lg w-[100%] lg:w-[19%] md:w-[19%] text-center mb-4">
                <h3>Active Loan</h3>
                <p className="lg:text-[28px] md:text-[28px] text-[20px] font-bold"><span>&#36;</span>4000</p>
              </div>
              <div className="bg-[#e0bb8314] shadow-lg border border-[#E0BB83]/30 p-6 rounded-lg w-[100%] lg:w-[19%] md:w-[19%] text-center mb-4">
                <h3>My Collateral</h3>
                <p className="lg:text-[28px] md:text-[28px] text-[20px] font-bold"><span>&#36;</span>4500</p>
              </div>
              <div className="bg-[#e0bb8314] shadow-lg border border-[#E0BB83]/30 p-6 rounded-lg w-[100%] lg:w-[19%] md:w-[19%] text-center mb-4">
                <h3>My Requests</h3>
                <p className="lg:text-[28px] md:text-[28px] text-[20px] font-bold">5</p>
              </div>
              <div className="bg-[#e0bb8314] shadow-lg border border-[#E0BB83]/30 p-6 rounded-lg w-[100%] lg:w-[19%] md:w-[19%] text-center mb-4">
                <h3>Repayment Amount</h3>
                <p className="lg:text-[28px] md:text-[28px] text-[20px] font-bold">&#36;5</p>
              </div>
            </div>
          </section>
          <section>
            <h3 className='text-[20px] font-playfair font-[700] my-4 text-[#E0BB83]'>Request Management</h3>
            <div className="flex justify-between flex-wrap">
              {isLoading ? <p>Loading...</p> : portfolioRes?.map((item, index) => (
                    <div key={index} className="w-[100%] lg:w-[31%] md:w-[31%] rounded-lg border border-[#E0BB83]/40  p-4 mt-6">
                      <Link to={`/dashboard/portfolio/${index}`}>
                        {/* {console.log(item?.interest_rate.toString())} */}
                        <img src='https://z-p3-scontent.fiba1-2.fna.fbcdn.net/o1/v/t0/f1/m247/2850021285355695016_2501028907_22-06-2024-04-34-56.jpeg?_nc_ht=z-p3-scontent.fiba1-2.fna.fbcdn.net&_nc_cat=102&ccb=9-4&oh=00_AYC1Z9Nt9gCWm8sHZ_yH-6sZYlv-w5ySnuMEa1F81h25RQ&oe=66794051&_nc_sid=5b3566' alt="" 
                        className="w-[100%] rounded-lg h-[200px] object-cover object-center mb-4" />
                        <p>Amount: {item?.amount.toString()}</p>
                        <p>Rate: {item?.interest_rate.toString()}<span>&#37;</span></p>
                        <p>Repayment: <span>&#36;</span>{item?.total_repayment.toString()}</p>
                        <p>Return date: <span>{(new Date(Number(item?.return_date) * 1000)).toLocaleString()}</span></p>
                      </Link>
                    </div>
                  ))}
            </div>
          </section>
          <section>
            <h3 className='text-[20px] font-playfair font-[700] my-4 text-[#E0BB83]'>Loan Repayment</h3>
          </section>
        </main>
      ) : (
        <ConnectWallet />
      )}
    </div>
  );
};

export default Portfolio;
