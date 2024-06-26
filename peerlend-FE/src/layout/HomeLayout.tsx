import React from "react"
import Header from "../components/Header"
import Footer from "../components/Footer"
import { Outlet, Navigate } from "react-router-dom"
import { useAccount } from "@starknet-react/core"

const HomeLayout = () => {
  const { status } = useAccount();

    return status === "connected" ? <Navigate to={'/dashboard'}/> : (
    <div>
        <Header />
        <Outlet />
        <Footer />
    </div>
  )
}

export default HomeLayout