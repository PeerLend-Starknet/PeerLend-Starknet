import React from 'react'
import Sidebar from '../components/Sidebar'
import { Outlet, Navigate } from 'react-router-dom'
import { useAccount } from '@starknet-react/core'

const DashboardLayout = () => {
  const { isConnected } = useAccount();
  return !isConnected ? <Navigate to={'/'}/> : (
    <div>
    <div className="flex justify-between items-center">
        <Sidebar />
        <div className="w-[100%] lg:w-[79%] md:w-[79%] h-auto lg:h-[80vh] md:h-[80vh] overflow-y-scroll p-8">
        <Outlet />
        </div>
    </div>
    </div>
  )
}

export default DashboardLayout