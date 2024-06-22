import React from "react";

interface ButtonProps extends React.ButtonHTMLAttributes<HTMLButtonElement> {
  children: React.ReactNode;
}

export const Button = ({ children, ...props }: ButtonProps) => {
  return (
    <button
      {...props}
      className={`bg-[#E0BB83] py-2 px-6 rounded-lg text-[#2a2a2a] font-[700] font-playfair disabled:opacity-50 ${props.className}`}
    >
      {children}
    </button>
  );
};
