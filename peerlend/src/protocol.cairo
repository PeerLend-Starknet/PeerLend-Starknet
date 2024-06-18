use starknet::ContractAddress;


#[starknet::interface]
pub trait IPeerlend<TContractState> {
    // read functions
    fn get_owner(self: @TContractState) -> ContractAddress;
    fn get_user_details(self: @TContractState, user_address: ContractAddress) -> Peerlend::UserInfo;
}

#[starknet::contract]
pub mod Peerlend {
    use core::traits::TryInto;
    use super::ContractAddress;
    use starknet::contract_address_const;

    use openzeppelin::access::ownable::OwnableComponent;
    use openzeppelin::access::ownable::ownable::OwnableComponent::InternalTrait;

    use peerlend::errors;

    component!(path: OwnableComponent, storage: ownable, event: OwnableEvent);

    #[storage]
    struct Storage {
        request_id: u64,
        collateral_token_id: u16,
        last_offer_id: LegacyMap<u64, u16>,
        collateral_tokens: LegacyMap<u16, ContractAddress>,
        price_feeds: LegacyMap<ContractAddress, ContractAddress>,
        collateral_deposited: LegacyMap<(ContractAddress, ContractAddress), u256>,
        user_info: LegacyMap<ContractAddress, UserInfo>,
        requests: LegacyMap<u64, Request>,
        offers: LegacyMap<(u64, u16), Offer>,
        #[substorage(v0)]
        ownable: OwnableComponent::Storage,
    }

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
        pub return_date: u16,
        pub lender: ContractAddress,
        pub status: Status,
        pub token_address: ContractAddress,
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
    pub enum Status {
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

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        #[flat]
        OwnableEvent: OwnableComponent::Event,
    }

    #[abi(embed_v0)]
    impl OwnableImpl = OwnableComponent::OwnableImpl<ContractState>;

    #[abi(embed_v0)]
    impl IPeerlendimpl of super::IPeerlend<ContractState> {
        fn get_owner(self: @ContractState) -> ContractAddress {
            self.ownable.owner()
        }

        fn get_user_details(self: @ContractState, user_address: ContractAddress) -> UserInfo {
            self.user_info.read(user_address)
        }
    }

    #[constructor]
    fn constructor(ref self: ContractState, owner: ContractAddress,// tokens: Array<ContractAddress>,
    // pricefeeds: Array<ContractAddress>
    ) {
        self.ownable.initializer(owner);
    // assert(tokens.len() == pricefeeds.len(), errors::LENGTH_MISMATCH);
    // let len = tokens.len();
    // let mut index: usize = 0;

    // while index < len {
    //     self.price_feeds.write(*tokens[index], *pricefeeds[index]);
    //     self.collateral_tokens.write(index.try_into().unwrap(), *tokens[index]);
    //     index += 1;
    // };

    // self.collateral_token_id.write(len.try_into().unwrap());
    }
}
