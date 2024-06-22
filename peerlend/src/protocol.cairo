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
    fn get_request_by_id(self: @TContractState, request_id: u64) -> Request;
    fn get_all_requests(self: @TContractState) -> Array<Request>;
    fn get_offers_for_request(self: @TContractState, request_id: u64) -> Array<Offer>;
    fn health_factor(self: @TContractState, user: ContractAddress, borrow_value: u256) -> u256;

    //write functions
    fn set_loanable_tokens(
        ref self: TContractState, tokens: Array<ContractAddress>, asset_id: Array<felt252>
    );
    fn deposit_collateral(ref self: TContractState, token: ContractAddress, amount: u256);
    fn withdraw_collateral(ref self: TContractState, token: ContractAddress, amount: u256);
    fn create_request(
        ref self: TContractState,
        amount: u256,
        interest_rate: u16,
        return_date: u64,
        loan_token: ContractAddress
    );
    fn service_request(ref self: TContractState, request_id: u64);
    fn make_offer(
        ref self: TContractState,
        request_id: u64,
        amount: u256,
        interest_rate: u16,
        return_date: u64
    );
    fn respond_to_offer(ref self: TContractState, request_id: u64, offer_id: u16, accept: bool);
    fn repay_loan(ref self: TContractState, request_id: u64, amount: u256);
}

#[starknet::contract]
pub mod Peerlend {
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

    const threshold: u16 = 8500; // 85% of the total collateral

    #[storage]
    struct Storage {
        total_request_ids: u64,
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
        RequestCreated: RequestCreated,
        RequestServiced: RequestServiced,
        OfferCreated: OfferCreated,
        #[flat]
        OwnableEvent: OwnableComponent::Event,
    }

    #[derive(Drop, starknet::Event)]
    struct CollateralDeposited {
        #[key]
        user: ContractAddress,
        #[key]
        token: ContractAddress,
        amount: u256,
    }

    #[derive(Drop, starknet::Event)]
    struct RequestCreated {
        #[key]
        request_id: u64,
        #[key]
        user: ContractAddress,
        #[key]
        loan_token: ContractAddress,
        amount: u256,
        interest_rate: u16,
        return_date: u64
    }

    #[derive(Drop, starknet::Event)]
    struct RequestServiced {
        #[key]
        request_id: u64,
        #[key]
        lender: ContractAddress,
        amount: u256
    }

    #[derive(Drop, starknet::Event)]
    struct OfferCreated {
        #[key]
        request_id: u64,
        #[key]
        offer_id: u16,
        #[key]
        lender: ContractAddress,
        amount: u256,
        interest_rate: u16
    }

    #[abi(embed_v0)]
    impl OwnableImpl = OwnableComponent::OwnableImpl<ContractState>;

    #[abi(embed_v0)]
    impl IPeerlendImpl of super::IPeerlend<ContractState> {
        fn get_owner(self: @ContractState) -> ContractAddress {
            self.ownable.owner()
        }

        fn get_user_details(self: @ContractState, user_address: ContractAddress) -> UserInfo {
            UserInfo { address: user_address, ..self.user_info.read(user_address) }
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
                let scaled_price = Private::_scale_price(
                    self, price.try_into().unwrap(), decimals, 8
                );
                total_collateral_usd += scaled_price;
                index += 1;
            };

            total_collateral_usd
        }

        fn get_request_by_id(self: @ContractState, request_id: u64) -> Request {
            assert(request_id < self.total_request_ids.read(), errors::REQUEST_ID_NOT_FOUND);
            self.requests.read(request_id)
        }

        fn get_all_requests(self: @ContractState) -> Array<Request> {
            let mut requests: Array<Request> = ArrayTrait::new();
            let mut index: u64 = 0;

            while index < self
                .total_request_ids
                .read() {
                    requests.append(self.requests.read(index));
                    index += 1;
                };

            requests
        }

        fn get_offers_for_request(self: @ContractState, request_id: u64) -> Array<Offer> {
            let mut offers: Array<Offer> = ArrayTrait::new();
            let mut index: u16 = 0;

            while index < self
                .last_offer_id
                .read(request_id) {
                    let offer = self.offers.read((request_id, index));
                    offers.append(offer);
                    index += 1;
                };

            offers
        }


        fn health_factor(self: @ContractState, user: ContractAddress, borrow_value: u256) -> u256 {
            Private::_health_factor(self, user, borrow_value)
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
            //     ERC20ABIDispatcher { contract_address: token }
            //         .transfer_from(caller, get_contract_address(), amount),
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

        fn create_request(
            ref self: ContractState,
            amount: u256,
            interest_rate: u16,
            return_date: u64,
            loan_token: ContractAddress
        ) {
            assert(self._is_loanable_token(loan_token), errors::NOT_LOANABLE_TOKEN);
            let caller = get_caller_address();
            let caller_info = self.get_user_details(caller);

            let (loan_amount_usd, decimals) = self.get_token_price_usd(loan_token, amount);
            let loan_amount_usd_scale = self
                ._scale_price(loan_amount_usd.try_into().unwrap(), decimals, 8);

            // tcv -> total collateral value
            let tcv = loan_amount_usd_scale + caller_info.current_loan;
            let _health_factor = self._health_factor(caller, tcv);
            assert(_health_factor >= 1, errors::INSUFFICIENT_COLLATERAL);

            let request_id = self.total_request_ids.read();

            let total_repayment = self._calculate_repayment(loan_amount_usd_scale, interest_rate);

            let request = Request {
                request_id: request_id,
                borrower: caller,
                amount,
                interest_rate,
                total_repayment,
                return_date,
                loan_token,
                status: RequestStatus::OPEN,
                lender: Zero::zero(),
            };
            self.requests.write(request_id, request);
            self.total_request_ids.write(request_id + 1);

            self
                .emit(
                    RequestCreated {
                        request_id, user: caller, amount, interest_rate, return_date, loan_token
                    }
                );
        }

        fn service_request(ref self: ContractState, request_id: u64) {
            let request = self.get_request_by_id(request_id);
            assert(request.status == RequestStatus::OPEN, errors::REQUEST_ALREADY_SERVICED);

            let caller = get_caller_address();
            assert(request.borrower != caller, errors::CANNOT_SERVICE_OWN_REQUEST);

            let caller_info = self.get_user_details(caller);
            let borrower_info = self.get_user_details(request.borrower);

            let (loan_amount_usd, decimals) = self
                .get_token_price_usd(request.loan_token, request.amount);
            let loan_amount_usd_scale = self
                ._scale_price(loan_amount_usd.try_into().unwrap(), decimals, 8);

            let total_repayment = self
                ._calculate_repayment(loan_amount_usd_scale, request.interest_rate);

            // update request status and lender
            self
                .requests
                .write(
                    request_id,
                    Request {
                        total_repayment, status: RequestStatus::SERVICED, lender: caller, ..request
                    }
                );

            // update borrower current loan and total amount borrowed
            self
                .user_info
                .write(
                    request.borrower,
                    UserInfo {
                        current_loan: borrower_info.current_loan + total_repayment,
                        total_amount_borrowed: borrower_info.total_amount_borrowed
                            + total_repayment,
                        ..borrower_info
                    },
                );

            // update lender total amount lent
            self
                .user_info
                .write(
                    caller,
                    UserInfo {
                        total_amount_lended: caller_info.total_amount_lended
                            + loan_amount_usd_scale,
                        ..caller_info
                    },
                );

            // transfer the loan amount to the borrower
            // TODO: fix the erc20 transfer_from call
            // let erc20_dispatcher = ERC20ABIDispatcher { contract_address: request.loan_token };
            // assert(
            //     ERC20ABIDispatcher { contract_address: request.loan_token }
            //         .transfer_from(caller, request.borrower, request.amount),
            //     errors::TRANSFER_FAILED
            // );

            self.emit(RequestServiced { request_id, lender: caller, amount: request.amount });
        }

        fn make_offer(
            ref self: ContractState,
            request_id: u64,
            amount: u256,
            interest_rate: u16,
            return_date: u64
        ) {
            let request = self.get_request_by_id(request_id);
            assert(request.status == RequestStatus::OPEN, errors::REQUEST_ALREADY_SERVICED);

            let caller = get_caller_address();
            assert(request.borrower != caller, errors::OWN_REQUEST);

            let offer_id = self.last_offer_id.read(request_id);

            let offer = Offer {
                offer_id,
                lender: caller,
                amount,
                interest_rate,
                return_date,
                status: OfferStatus::PENDING,
            };

            self.offers.write((request_id, offer_id), offer);

            self.last_offer_id.write(request_id, offer_id + 1);

            self.emit(OfferCreated { request_id, offer_id, lender: caller, amount, interest_rate });
        }

        fn respond_to_offer(ref self: ContractState, request_id: u64, offer_id: u16, accept: bool) {
            let caller = get_caller_address();
            let request = self.get_request_by_id(request_id);
            assert(request.borrower == caller, errors::NOT_REQUEST_OWNER);
            assert(request.status == RequestStatus::OPEN, errors::REQUEST_ALREADY_SERVICED);

            let last_offer = self.last_offer_id.read(request_id);
            assert(offer_id < last_offer, errors::OFFER_ID_NOT_FOUND);

            let offer = self.offers.read((request_id, offer_id));

            assert(offer.status == OfferStatus::PENDING, errors::OFFER_NOT_PENDING);

            if accept {
                let borrower_info = self.get_user_details(request.borrower);
                let lender_info = self.get_user_details(offer.lender);

                let (loan_amount_usd, decimals) = self
                    .get_token_price_usd(request.loan_token, offer.amount);
                let loan_amount_usd_scale = self
                    ._scale_price(loan_amount_usd.try_into().unwrap(), decimals, 8);

                let total_repayment = self
                    ._calculate_repayment(loan_amount_usd_scale, offer.interest_rate);

                // update request status and lender
                self
                    .requests
                    .write(
                        request_id,
                        Request {
                            total_repayment,
                            status: RequestStatus::SERVICED,
                            amount: offer.amount,
                            lender: offer.lender,
                            interest_rate: offer.interest_rate,
                            ..request
                        }
                    );

                // update borrower current loan and total amount borrowed
                self
                    .user_info
                    .write(
                        request.borrower,
                        UserInfo {
                            current_loan: borrower_info.current_loan + total_repayment,
                            total_amount_borrowed: borrower_info.total_amount_borrowed
                                + loan_amount_usd_scale,
                            ..borrower_info
                        },
                    );

                // update lender total amount lent
                self
                    .user_info
                    .write(
                        offer.lender,
                        UserInfo {
                            total_amount_lended: lender_info.total_amount_lended
                                + loan_amount_usd_scale,
                            ..lender_info
                        },
                    );

                // make other offers rejected
                self._resolve_offers(request_id, offer_id);

                // transfer the loan amount to the borrower
                assert(
                    ERC20ABIDispatcher { contract_address: request.loan_token }
                        .transfer_from(offer.lender, request.borrower, offer.amount),
                    errors::TRANSFER_FAILED
                );
            } else {
                self
                    .offers
                    .write(
                        (request_id, offer_id), Offer { status: OfferStatus::REJECTED, ..offer }
                    );
            }
        }

        fn repay_loan(ref self: ContractState, request_id: u64, amount: u256) {
            assert(request_id < self.total_request_ids.read(), errors::REQUEST_ID_NOT_FOUND);
            let request = self.get_request_by_id(request_id);
            let caller = get_caller_address();
            assert(request.borrower == caller, errors::NOT_REQUEST_OWNER);
            assert(request.status == RequestStatus::SERVICED, errors::REQUEST_NOT_SERVICED);

            let caller_info = self.get_user_details(caller);
            let (loan_amount_usd, decimals) = self.get_token_price_usd(request.loan_token, amount);
            let loan_amount_usd_scale = self
                ._scale_price(loan_amount_usd.try_into().unwrap(), decimals, 8);

            if request.total_repayment < loan_amount_usd_scale {
                self
                    .requests
                    .write(
                        request_id,
                        Request { total_repayment: 0, status: RequestStatus::CLOSED, ..request }
                    );
            } else {
                let new_total_repayment = request.total_repayment - loan_amount_usd_scale;
                self
                    .requests
                    .write(request_id, Request { total_repayment: new_total_repayment, ..request });
            }

            let mut new_current_loan = caller_info.current_loan;

            if caller_info.current_loan < loan_amount_usd_scale {
                new_current_loan = 0;
            } else {
                new_current_loan -= loan_amount_usd_scale;
            }

            self
                .user_info
                .write(
                    caller,
                    UserInfo {
                        current_loan: new_current_loan,
                        total_amount_repaid: (caller_info.total_amount_repaid
                            + loan_amount_usd_scale),
                        ..caller_info
                    }
                );
        // assert(
        //     ERC20ABIDispatcher { contract_address: request.loan_token }
        //         .transfer_from(caller, request.lender, amount),
        //     errors::TRANSFER_FAILED
        // );
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

        fn _scale_price(
            self: @ContractState, price: u128, price_decimals: u32, decimals: u32
        ) -> u256 {
            if price_decimals > decimals {
                return (price / fast_power(10, price_decimals - decimals).into()).into();
            } else {
                return (price * fast_power(10, decimals - price_decimals).into()).into();
            }
            price.into()
        }

        fn _health_factor(self: @ContractState, user: ContractAddress, borrow_value: u256) -> u256 {
            let total_collateral_usd = self.get_total_collateral_deposited_usd(user);
            let health_factor = total_collateral_usd * threshold.into() / borrow_value / 10000;
            health_factor
        }

        fn _calculate_repayment(self: @ContractState, amount: u256, interest_rate: u16) -> u256 {
            let interest = amount * interest_rate.into() / 100;
            amount + interest
        }

        fn _resolve_offers(ref self: ContractState, request_id: u64, offer_id: u16) {
            let mut index: u16 = 0;
            let last_offer_id = self.last_offer_id.read(request_id);

            while index < last_offer_id {
                let offer = self.offers.read((request_id, index));
                if index != offer_id {
                    self
                        .offers
                        .write(
                            (request_id, index), Offer { status: OfferStatus::REJECTED, ..offer },
                        );
                } else {
                    self
                        .offers
                        .write(
                            (request_id, index), Offer { status: OfferStatus::ACCEPTED, ..offer },
                        );
                }
                index += 1;
            };
        }
    }

    #[constructor]
    fn constructor(ref self: ContractState, owner: ContractAddress, datafeed: ContractAddress) {
        self.ownable.initializer(owner);
        self.datafeed.write(datafeed);
    }
}
