use starknet::ContractAddress;
use peerlend::types::{UserInfo, Request, Offer, RequestStatus, OfferStatus};


#[starknet::interface]
pub trait IPeerlend<TContractState> {
    // read functions
    fn get_owner(self: @TContractState) -> ContractAddress;
    fn get_user_details(self: @TContractState, user_address: ContractAddress) -> UserInfo;
    fn get_collateral_token_id(self: @TContractState) -> u16;
    fn get_collateral_deposited(
        self: @TContractState, user: ContractAddress, token: ContractAddress
    ) -> u256;
    fn get_asset_price(self: @TContractState, asset_id: felt252) -> (u128, u32);
    fn get_token_price_usd(
        self: @TContractState, token: ContractAddress, amount: u256
    ) -> (u256, u32);

    fn get_total_collateral_deposited_usd(self: @TContractState, user: ContractAddress) -> u256;

    //write functions
    fn set_loanable_tokens(
        ref self: TContractState, tokens: Array<ContractAddress>, asset_id: Array<felt252>
    );
    fn deposit_collateral(ref self: TContractState, token: ContractAddress, amount: u256);
    fn withdraw_collateral(ref self: TContractState, token: ContractAddress, amount: u256);
}

#[starknet::contract]
pub mod Peerlend {
    // use core::traits::TryInto;
    use core::option::OptionTrait;
    use core::traits::TryInto;
    use core::traits::Into;
    use core::starknet::event::EventEmitter;
    use core::num::traits::Zero;
    use super::ContractAddress;
    use starknet::{get_caller_address, get_contract_address, contract_address_const};

    use openzeppelin::access::ownable::OwnableComponent;
    use openzeppelin::access::ownable::ownable::OwnableComponent::InternalTrait;
    use openzeppelin::token::erc20::interface::{ERC20ABIDispatcher, ERC20ABIDispatcherTrait};

    use alexandria_math::fast_power::fast_power;

    use pragma_lib::abi::{
        IPragmaABIDispatcher, IPragmaABIDispatcherTrait, ISummaryStatsABIDispatcher,
        ISummaryStatsABIDispatcherTrait
    };
    use pragma_lib::types::{DataType, AggregationMode, PragmaPricesResponse};

    use peerlend::errors;
    use peerlend::types::{UserInfo, Request, Offer, RequestStatus, OfferStatus};

    component!(path: OwnableComponent, storage: ownable, event: OwnableEvent);

    const threshold: u256 = 8500; // 85% of the total collateral

    #[storage]
    struct Storage {
        request_id: u64,
        collateral_token_id: u16,
        last_offer_id: LegacyMap<u64, u16>,
        collateral_tokens: LegacyMap<u16, ContractAddress>,
        token_asset_id: LegacyMap<ContractAddress, felt252>,
        loanable: LegacyMap<ContractAddress, bool>,
        collateral_deposited: LegacyMap<(ContractAddress, ContractAddress), u256>,
        user_info: LegacyMap<ContractAddress, UserInfo>,
        requests: LegacyMap<u64, Request>,
        offers: LegacyMap<(u64, u16), Offer>,
        datafeed: ContractAddress,
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
    impl IPeerlendImpl of super::IPeerlend<ContractState> {
        fn get_owner(self: @ContractState) -> ContractAddress {
            self.ownable.owner()
        }

        fn get_user_details(self: @ContractState, user_address: ContractAddress) -> UserInfo {
            self.user_info.read(user_address)
        }

        fn get_collateral_token_id(self: @ContractState) -> u16 {
            self.collateral_token_id.read()
        }

        fn get_collateral_deposited(
            self: @ContractState, user: ContractAddress, token: ContractAddress
        ) -> u256 {
            self.collateral_deposited.read((user, token))
        }

        fn get_asset_price(self: @ContractState, asset_id: felt252) -> (u128, u32) {
            let datafeed_address = self.datafeed.read();
            let oracle_dispatcher = IPragmaABIDispatcher { contract_address: datafeed_address };
            let output: PragmaPricesResponse = oracle_dispatcher
                .get_data_median(DataType::SpotEntry(asset_id));
            (output.price, output.decimals)
        }

        fn get_token_price_usd(
            self: @ContractState, token: ContractAddress, amount: u256
        ) -> (u256, u32) {
            let token_decimals = ERC20ABIDispatcher { contract_address: token }.decimals();
            let asset_id = self.token_asset_id.read(token);
            let (asset_price, decimals) = IPeerlendImpl::get_asset_price(self, asset_id);
            let mut price = amount * asset_price.into();
            (price / fast_power(10, token_decimals.try_into().unwrap()), decimals)
        }

        fn get_total_collateral_deposited_usd(self: @ContractState, user: ContractAddress) -> u256 {
            let mut total_collateral_usd: u256 = 0;
            let len = self.collateral_token_id.read();
            let mut index: u16 = 0;

            while index < len {
                let token = self.collateral_tokens.read(index);
                let amount = self.collateral_deposited.read((user, token));
                let (price, decimals) = self.get_token_price_usd(token, amount);
                let scaled_price = Private::scale_price(
                    self, price.try_into().unwrap(), decimals, 8
                );
                total_collateral_usd += scaled_price;
                index += 1;
            };

            total_collateral_usd
        }


        fn deposit_collateral(ref self: ContractState, token: ContractAddress, amount: u256) {
            assert(self._is_loanable_token(token), errors::CANNOT_COLLATERALIZE);
            let caller = get_caller_address();
            //TODO: fix the erc20 transfer_from call
            // let this_address = get_contract_address();

            let prev_balance = self.collateral_deposited.read((caller, token));
            let new_balance = prev_balance + amount;
            self.collateral_deposited.write((caller, token), new_balance);

            // let erc20_dispatcher = ERC20ABIDispatcher { contract_address: token };
            // assert(
            //     erc20_dispatcher.transfer_from(caller, this_address, amount),
            //     errors::TRANSFER_FAILED
            // );
            self.emit(CollateralDeposited { user: caller, token, amount });
        }

        fn withdraw_collateral(ref self: ContractState, token: ContractAddress, amount: u256) {
            let caller = get_caller_address();
            let prev_balance = self.collateral_deposited.read((caller, token));
            assert(prev_balance >= amount, errors::INSUFFICIENT_BALANCE);
            let new_balance = prev_balance - amount;
            self.collateral_deposited.write((caller, token), new_balance);
            let erc20_dispatcher = ERC20ABIDispatcher { contract_address: token };
            assert(erc20_dispatcher.transfer(caller, amount), errors::TRANSFER_FAILED);
        }

        fn set_loanable_tokens(
            ref self: ContractState, tokens: Array<ContractAddress>, asset_id: Array<felt252>
        ) {
            self.ownable.assert_only_owner();
            let len = tokens.len();
            let mut index: usize = 0;

            assert(tokens.len() == asset_id.len(), errors::LENGTH_MISMATCH);

            while index < len {
                self.loanable.write(*tokens[index], true);
                self.collateral_tokens.write(index.try_into().unwrap(), *tokens[index]);
                self.token_asset_id.write(*tokens[index], *asset_id[index]);
                index += 1;
            };

            self
                .collateral_token_id
                .write(self.collateral_token_id.read() + len.try_into().unwrap());
        }
    }

    #[generate_trait]
    pub impl Private of PrivateTrait {
        fn _is_loanable_token(self: @ContractState, token: ContractAddress) -> bool {
            self.loanable.read(token)
        }

        fn scale_price(
            self: @ContractState, price: u128, price_decimals: u32, decimals: u32
        ) -> u256 {
            if price_decimals > decimals {
                return (price / fast_power(10, price_decimals - decimals).into()).into();
            } else {
                return (price * fast_power(10, decimals - price_decimals).into()).into();
            }
            price.into()
        }
    }

    #[constructor]
    fn constructor(ref self: ContractState, owner: ContractAddress, datafeed: ContractAddress) {
        self.ownable.initializer(owner);
        self.datafeed.write(datafeed);
    }
}
