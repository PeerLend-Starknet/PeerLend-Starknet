use starknet::ContractAddress;
use peerlend::types::{UserInfo, Request, Offer, RequestStatus, OfferStatus};


#[starknet::interface]
pub trait IPeerlend<TContractState> {
    // read functions
    fn get_owner(self: @TContractState) -> ContractAddress;
    fn get_user_details(self: @TContractState, user_address: ContractAddress) -> UserInfo;
    fn get_collateral_token_id(self: @TContractState) -> u16;
    fn get_collateral_deposited(self: @TContractState, token: ContractAddress) -> u256;
    // fn get_total_collateral_deposited_usd(self: @TContractState) -> u256;

    //write functions
    fn set_loanable_tokens(ref self: TContractState, tokens: Array<ContractAddress>);
    fn deposit_collateral(ref self: TContractState, token: ContractAddress, amount: u256);
}

#[starknet::contract]
pub mod Peerlend {
    // use core::traits::TryInto;
    use core::starknet::event::EventEmitter;
    use core::num::traits::Zero;
    use super::ContractAddress;
    use starknet::{get_caller_address, get_contract_address, contract_address_const};

    use openzeppelin::access::ownable::OwnableComponent;
    use openzeppelin::access::ownable::ownable::OwnableComponent::InternalTrait;
    use openzeppelin::token::erc20::interface::{IERC20Dispatcher, IERC20DispatcherTrait};

    use peerlend::errors;
    use peerlend::types::{UserInfo, Request, Offer, RequestStatus, OfferStatus};

    component!(path: OwnableComponent, storage: ownable, event: OwnableEvent);

    #[storage]
    struct Storage {
        request_id: u64,
        collateral_token_id: u16,
        last_offer_id: LegacyMap<u64, u16>,
        collateral_tokens: LegacyMap<u16, ContractAddress>,
        loanable: LegacyMap<ContractAddress, bool>,
        collateral_deposited: LegacyMap<(ContractAddress, ContractAddress), u256>,
        user_info: LegacyMap<ContractAddress, UserInfo>,
        requests: LegacyMap<u64, Request>,
        offers: LegacyMap<(u64, u16), Offer>,
        #[substorage(v0)]
        ownable: OwnableComponent::Storage,
    }


    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        CollateralDeposited: CollateralDeposited,
        #[flat]
        OwnableEvent: OwnableComponent::Event,
    }

    #[derive(Drop, starknet::Event)]
    struct CollateralDeposited {
        user: ContractAddress,
        token: ContractAddress,
        amount: u256,
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

        fn get_collateral_token_id(self: @ContractState) -> u16 {
            self.collateral_token_id.read()
        }

        fn get_collateral_deposited(self: @ContractState, token: ContractAddress) -> u256 {
            let caller = get_caller_address();
            self.collateral_deposited.read((caller, token))
        }


        fn deposit_collateral(ref self: ContractState, token: ContractAddress, amount: u256) {
            assert(self._is_loanable_token(token), errors::CANNOT_COLLATERALIZE);
            let caller = get_caller_address();
            let this_address = get_contract_address();

            let prev_balance = self.collateral_deposited.read((caller, token));
            self.collateral_deposited.write((caller, token), prev_balance + amount);

            let erc20_dispatcher = IERC20Dispatcher { contract_address: token };
            assert(
                erc20_dispatcher.transfer_from(caller, this_address, amount),
                errors::TRANSFER_FAILED
            );
            self.emit(CollateralDeposited { user: caller, token, amount });
        }

        fn set_loanable_tokens(ref self: ContractState, tokens: Array<ContractAddress>) {
            self.ownable.assert_only_owner();
            let len = tokens.len();
            let mut index: usize = 0;

            while index < len {
                self.loanable.write(*tokens[index], true);
                self.collateral_tokens.write(index.try_into().unwrap(), *tokens[index]);
                index += 1;
            };

            self
                .collateral_token_id
                .write(self.collateral_token_id.read() + len.try_into().unwrap());
        }
    }

    #[generate_trait]
    impl Private of PrivateTrait {
        fn _is_loanable_token(self: @ContractState, token: ContractAddress) -> bool {
            self.loanable.read(token)
        }
    }

    #[constructor]
    fn constructor(ref self: ContractState, owner: ContractAddress) {
        self.ownable.initializer(owner);
    }
}
