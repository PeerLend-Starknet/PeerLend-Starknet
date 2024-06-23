/// <reference types="vite/client" />
type ITokenList = {
    [key: string]: IToken;
}

interface IToken {
    name: string;
    symbol: string;
    address: string;
    decimals: number;
}