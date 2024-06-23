import { useContractRead } from '@starknet-react/core';

// Reusable hook for reading contract data
// eslint-disable-next-line @typescript-eslint/no-explicit-any
const useReadContract = (abi: any, address: any, functionName: string, args = []) => {
  const { data, isLoading } = useContractRead({
    abi,
    address,
    functionName,
    args
  });

  return { data, isLoading };
};

export default useReadContract;
