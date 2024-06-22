use starknet::ContractAddress;

#[derive(Drop, Serde, starknet::Store)]
pub struct UserInfo {
    pub address: ContractAddress,
    pub total_amount_borrowed: u256,
    pub total_amount_repaid: u256,
    pub total_amount_lended: u256,
    pub current_loan: u256,
}

#[derive(Drop, Serde, starknet::Store)]
pub struct Request {
    pub request_id: u64,
    pub borrower: ContractAddress,
    pub amount: u256,
    pub interest_rate: u16,
    pub total_repayment: u256,
    pub return_date: u64,
    pub lender: ContractAddress,
    pub status: RequestStatus,
    pub loan_token: ContractAddress,
}

#[derive(Drop, Serde, starknet::Store)]
pub struct Offer {
    pub offer_id: u16,
    pub lender: ContractAddress,
    pub amount: u256,
    pub interest_rate: u16,
    pub return_date: u16,
    pub status: OfferStatus,
    pub token_address: ContractAddress,
}

#[derive(Drop, Serde, starknet::Store)]
pub enum RequestStatus {
    OPEN,
    SERVICED,
    CLOSED,
}

#[derive(Drop, Serde, starknet::Store)]
pub enum OfferStatus {
    OPEN,
    ACCEPTED,
    REJECTED,
}

