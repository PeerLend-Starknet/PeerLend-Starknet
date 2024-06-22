import React from 'react'
import logo from '../assets/logo.svg'
import { NavLink } from 'react-router-dom'
import { useState } from 'react'
import { Sling as Hamburger } from 'hamburger-react'
import ConnectWallet from './ConnectWallet'

const Header = () => {
  const [isOpen, setOpen] = useState(false)

  return (
   <header className='py-8 sticky top-0 w-[100%] font-playfair font-[400] lg:text-[18px] md:text-[18px] text-[16px] bg-[#2a2a2a] z-50'>
    <div className='w-[90%] mx-auto hidden lg:flex md:flex items-center justify-between'>
    <NavLink to='/'><p className='text-[18px] flex items-center'><img src={logo} alt="" className='w-[40px] h-[40px] '/>
   PeerLend</p></NavLink>
    <div className='flex items-center justify-between'>
        <a href='#about' className='mr-12'>About Us</a>
        <a href='#contact'className='mr-12'>Contact</a>
        <NavLink to=''>Blog</NavLink>
    </div>
    <ConnectWallet />
   </div>
   <nav className='lg:hidden md:hidden flex justify-between w-[90%] mx-auto'>  
   <p className='text-[18px] flex items-center'><img src={logo} alt="" className='w-[40px] h-[40px] '/>
   PeerLend</p>
<Hamburger toggled={isOpen} toggle={setOpen} />
   {isOpen && (
        <div className='flex flex-col absolute bg-[#2a2a2a] w-[90%] text-center top-full mt-2 z-50 px-6 py-10'>
            <NavLink to='#about' className='mb-8'>About Us</NavLink>
            <a href='#about' className='mb-8'>About Us</a>
        <a href='#contact'className='mb-8'>Contact</a>
        <ConnectWallet />
        </div>
   )}
    </nav>
   </header>
  )
}

export default Header