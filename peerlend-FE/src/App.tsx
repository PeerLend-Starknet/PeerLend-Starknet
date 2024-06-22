import React from "react";
import { 
  createBrowserRouter, 
  Route, 
  createRoutesFromElements, 
  RouterProvider 
} from "react-router-dom";
import Home from "./pages/Home";
import HomeLayout from "./layout/HomeLayout";


const router = createBrowserRouter(createRoutesFromElements(
  <Route>
  <Route path="/" element={<HomeLayout />} >
    <Route index element={<Home />} />
  </Route>
 
  </Route>
))

function App() {

    return (
      <div className="text-[#FFF] bg-[#2a2a2a] lg:max-w-[1440px] md:max-w-[1440px] font-roboto-serif font-[100]">
        <RouterProvider router={router} />
    </div> 
    )
}

export default App