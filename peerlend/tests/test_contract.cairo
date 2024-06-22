use core::traits::TryInto;
use core::option::OptionTrait;
use starknet::{ContractAddress, contract_address_const, get_block_timestamp};

use snforge_std::{
    declare, ContractClassTrait, spy_events, SpyOn, EventSpy, EventAssertions, CheatSpan,
    cheat_caller_address, stop_cheat_caller_address, cheat_caller_address_global,
    stop_cheat_caller_address_global
};

use core::num::traits::Zero;

use openzeppelin::access::ownable::interface::IOwnable;
use openzeppelin::access::ownable::interface::IOwnableDispatcher;

use peerlend::protocol::{
    IPeerlendSafeDispatcher, IPeerlendSafeDispatcherTrait, IPeerlendDispatcher,
    IPeerlendDispatcherTrait
};
use peerlend::types::{UserInfo, Request, RequestStatus, OfferStatus};

use openzeppelin::token::erc20::interface::{ERC20ABIDispatcher, ERC20ABIDispatcherTrait};

use alexandria_math::fast_power::fast_power;


const eth_strk_holder: felt252 = 0x0213c67ed78bc280887234fe5ed5e77272465317978ae86c25a71531d9332a2d;
const usdt_holder: felt252 = 0x02c4cae26ffd948639154cc2baa91f48c1e7a39b7a456a473f4f17d2ade96877;
const usdc_holder: felt252 = 0x01c27cb555fdb7704d63c4b7ca7e5dfa1bc73872e762896e77b64d08235a821d;

const strk_address: felt252 = 0x04718f5a0fc34cc1af16a1cdee98ffb20c31f5cd61d6ab07201858f4287c938d;
const eth_address: felt252 = 0x049d36570d4e46f48e99674bd3fcc84644ddd6b96f7c741b1562b82f9e004dc7;
const usdt_address: felt252 = 0x068f5c6a61780768455de69077e07e89787839bf8166decfbf92b645209c0fb8;
const usdc_address: felt252 = 0x053c91253bc9682c04929ca02ed00b3e423f6710d2ee7e0d5ebb06f3ecf368a8;

const mainnet_datafeed: felt252 = 0x2a85bd616f912537c50a49a4076db02c00b29b2cdc8a197ce92ed1837fa875b;
const sepolia_datafeed: felt252 = 0x36031daa264c24520b11d93af622c848b2499b66b41d611bac95e13cfca131a;

const eth_price: u128 = 355025483358;
const strk_price: u128 = 73327061;
const usdt_price: u128 = 999537;
const usdc_price: u128 = 999939;


#[test]
fn test_deployment() {
    let contract_address = deploy_contract("Peerlend");

    let dispatcher = IPeerlendDispatcher { contract_address: contract_address };

    let owner: ContractAddress = dispatcher.get_owner();
    assert(owner == 0xbeef.try_into().unwrap(), 'Invalid owner');
}

#[test]
fn test_get_user_details() {
    let contract_address = deploy_contract("Peerlend");

    let dispatcher = IPeerlendDispatcher { contract_address: contract_address };

    let user_address = 0xbeef.try_into().unwrap();
    prank_caller_address(contract_address, user_address, 1);
    let user_details = dispatcher.get_user_details(user_address);

    assert(user_details.address == user_address, 'Invalid user address');
    assert(user_details.total_amount_borrowed == 0, 'Invalid lender');
    assert(user_details.total_amount_repaid == 0, 'Invalid amount repaid');
    assert(user_details.total_amount_lended == 0, 'Invalid amount lended');
    assert(user_details.current_loan == 0, 'Invalid lender balance');
}

#[test]
fn test_set_loanable_tokens() {
    let contract_address = deploy_contract("Peerlend");

    let dispatcher = IPeerlendDispatcher { contract_address: contract_address };

    let user_address: ContractAddress = 0xbeef.try_into().unwrap();
    prank_caller_address(contract_address, user_address, 1);

    let mut tokens: Array<ContractAddress> = ArrayTrait::new();
    tokens.append('eth'.try_into().unwrap());
    tokens.append('usdt'.try_into().unwrap());
    tokens.append('usdc'.try_into().unwrap());

    let mut asset_id: Array<felt252> = ArrayTrait::new();
    asset_id.append('ETH/USD');
    asset_id.append('USDT/USD');
    asset_id.append('USDC/USD');

    dispatcher.set_loanable_tokens(tokens, asset_id);

    assert(dispatcher.get_collateral_token_id() == 3, 'Invalid collateral token id');
}

#[test]
#[fork("mainnet")]
fn test_deposit_collateral() {
    let contract_address = deploy_contract("Peerlend");

    let dispatcher = IPeerlendDispatcher { contract_address };
    add_loanable_tokens(dispatcher);
    let user_address: ContractAddress = usdc_holder.try_into().unwrap();
    let usdc: ContractAddress = usdc_address.try_into().unwrap();

    cheat_caller_address_global(user_address);

    let usdc_amount: u256 = 1000 * fast_power(10, 6);

    let usdc_dispatcher = ERC20ABIDispatcher { contract_address: usdc };
    usdc_dispatcher.approve(contract_address, usdc_amount);

    dispatcher.deposit_collateral(usdc, usdc_amount);

    stop_cheat_caller_address_global();

    assert(
        dispatcher.get_collateral_deposited(user_address, usdc) == usdc_amount,
        'Invalid usdc balance'
    );
}

#[test]
#[fork("mainnet")]
fn test_withdraw_collateral() {
    let contract_address = deploy_contract("Peerlend");
    let dispatcher = IPeerlendDispatcher { contract_address };
    add_loanable_tokens(dispatcher);

    let user_address: ContractAddress = usdc_holder.try_into().unwrap();
    let usdc: ContractAddress = usdc_address.try_into().unwrap();

    cheat_caller_address_global(user_address);

    let usdc_amount: u256 = 1000 * fast_power(10, 6);
    let withdraw_amount: u256 = 500 * fast_power(10, 6);

    let usdc_dispatcher = ERC20ABIDispatcher { contract_address: usdc };

    usdc_dispatcher.approve(contract_address, usdc_amount);
    dispatcher.deposit_collateral(usdc, usdc_amount);

    dispatcher.withdraw_collateral(usdc, withdraw_amount);

    stop_cheat_caller_address_global();

    assert(
        dispatcher.get_collateral_deposited(user_address, usdc) == (usdc_amount - withdraw_amount),
        'Invalid usdc balance'
    );
}

#[test]
#[fork("mainnet")]
fn test_get_asset_price() {
    let contract_address = deploy_contract("Peerlend");

    let dispatcher = IPeerlendDispatcher { contract_address };

    let (_eth_price, _) = dispatcher.get_asset_price('ETH/USD');
    let (_strk_price, _) = dispatcher.get_asset_price('STRK/USD');
    let (_usdt_price, _) = dispatcher.get_asset_price('USDT/USD');
    let (_usdc_price, _) = dispatcher.get_asset_price('USDC/USD');

    assert(eth_price == _eth_price, 'Invalid eth price');
    assert(strk_price == _strk_price, 'Invalid strk price');
    assert(usdt_price == _usdt_price, 'Invalid usdt price');
    assert(usdc_price == _usdc_price, 'Invalid usdc price');
}
#[test]
#[fork("mainnet")]
fn test_token_price_usd() {
    let contract_address = deploy_contract("Peerlend");

    let dispatcher = IPeerlendDispatcher { contract_address };
    add_loanable_tokens(dispatcher);

    let eth = contract_address_const::<eth_address>();
    let usdt = contract_address_const::<usdt_address>();
    let amount = 1000 * fast_power(10, 18);
    let amount2 = 1000 * fast_power(10, 6);

    let (_eth_price, _) = dispatcher.get_token_price_usd(eth, amount);
    let (_usdt_price, _) = dispatcher.get_token_price_usd(usdt, amount2);

    assert(eth_price.into() * 1000 == _eth_price.into(), 'Invalid eth price');
    assert(usdt_price.into() * 1000 == _usdt_price.into(), 'Invalid usdt price');
}

#[test]
#[fork("mainnet")]
fn test_get_total_collateral_deposited_usd() {
    let contract_address = deploy_contract("Peerlend");

    let dispatcher = IPeerlendDispatcher { contract_address };
    add_loanable_tokens(dispatcher);

    let user_address: ContractAddress = eth_strk_holder.try_into().unwrap();

    let eth_amount: u256 = 1 * fast_power(10, 18);
    let strk_amount: u256 = 100 * fast_power(10, 18);

    deposit_collateral(dispatcher, eth_strk_holder, eth_address, eth_amount, 18);
    deposit_collateral(dispatcher, eth_strk_holder, strk_address, strk_amount, 18);

    // let total_collateral = dispatcher.get_total_collateral_deposited_usd(user_address);
    let total_collateral_usd = (eth_price + (strk_price * 100)) * fast_power(10, 18);

    assert(
        dispatcher.get_total_collateral_deposited_usd(user_address) == total_collateral_usd.into(),
        'Invalid total collateral usd'
    );
}

#[test]
#[fork("mainnet")]
fn test_health_factor() {
    let contract_address = deploy_contract("Peerlend");

    let dispatcher = IPeerlendDispatcher { contract_address };
    add_loanable_tokens(dispatcher);

    let user_address: ContractAddress = eth_strk_holder.try_into().unwrap();
    let eth = contract_address_const::<eth_address>();

    let eth_amount: u256 = 1;

    deposit_collateral(dispatcher, eth_strk_holder, eth_address, eth_amount, 18);

    let (total_borrowed_usd, _) = dispatcher.get_token_price_usd(eth, 25 * fast_power(10, 16));

    assert!(dispatcher.health_factor(user_address, total_borrowed_usd) == 3, "Wrong health factor");
}

#[test]
#[fork("mainnet")]
fn test_create_request() {
    let contract_address = deploy_contract("Peerlend");

    let dispatcher = IPeerlendDispatcher { contract_address };
    add_loanable_tokens(dispatcher);

    let user_address: ContractAddress = eth_strk_holder.try_into().unwrap();
    // let eth = contract_address_const::<eth_address>();
    let usd = contract_address_const::<usdt_address>();

    let eth_amount: u256 = 1;

    let usd_amount: u256 = 2000 * fast_power(10, 6);
    let return_date = get_block_timestamp() + (60 * 60 * 24 * 30);

    deposit_collateral(dispatcher, eth_strk_holder, eth_address, eth_amount, 18);

    cheat_caller_address_global(user_address);

    let collateral = dispatcher.get_total_collateral_deposited_usd(user_address);

    println!("Collateral: {}", collateral);

    dispatcher.create_request(usd_amount, 3, return_date, usd);

    let request = dispatcher.get_request_by_id(0);

    assert(request.amount == usd_amount, 'Wrong request price');
}

#[test]
#[fork("mainnet")]
fn test_service_request() {
    let contract_address = deploy_contract("Peerlend");

    let dispatcher = IPeerlendDispatcher { contract_address };
    add_loanable_tokens(dispatcher);

    let borrower = contract_address_const::<eth_strk_holder>();
    let lender = contract_address_const::<usdt_holder>();

    let usdt = contract_address_const::<usdt_address>();

    let eth_amount: u256 = 1;

    let usd_amount: u256 = 2000 * fast_power(10, 6);
    let return_date = get_block_timestamp() + (60 * 60 * 24 * 30);

    deposit_collateral(dispatcher, eth_strk_holder, eth_address, eth_amount, 18);
    cheat_caller_address_global(borrower);

    dispatcher.create_request(usd_amount, 3, return_date, usdt);

    cheat_caller_address_global(lender);

    ERC20ABIDispatcher { contract_address: usdt }.approve(contract_address, usd_amount);
    dispatcher.service_request(0);

    let request = dispatcher.get_request_by_id(0);

    assert(request.status == RequestStatus::SERVICED, 'Wrong request status');
    assert(request.lender == lender, 'Wrong lender');

    let lender_details = dispatcher.get_user_details(lender);
    let borrower_details = dispatcher.get_user_details(borrower);

    assert(lender_details.total_amount_lended == 199907400000, 'Wrong total amount lended');
    assert(borrower_details.total_amount_borrowed == 199907400000, 'Wrong total amount borrowed');
    assert(borrower_details.current_loan == 199907400000, 'Wrong current loan');
}

// #[test]
// #[feature("safe_dispatcher")]
// fn test_cannot_increase_balance_with_zero_value() {
//     let contract_address = deploy_contract("HelloStarknet");

//     let safe_dispatcher = IHelloStarknetSafeDispatcher { contract_address };

//     let balance_before = safe_dispatcher.get_balance().unwrap();
//     assert(balance_before == 0, 'Invalid balance');

//     match safe_dispatcher.increase_balance(0) {
//         Result::Ok(_) => core::panic_with_felt252('Should have panicked'),
//         Result::Err(panic_data) => {
//             assert(*panic_data.at(0) == 'Amount cannot be 0', *panic_data.at(0));
//         }
//     };
// }

fn deploy_contract(name: ByteArray) -> ContractAddress {
    let owner: ContractAddress = 0xbeef.try_into().unwrap();
    let contract = declare(name).unwrap();
    let calldata: Array<felt252> = array![owner.into(), mainnet_datafeed];
    let (contract_address, _) = contract.deploy(@calldata).unwrap();
    contract_address
}


fn prank_caller_address(target: ContractAddress, caller: ContractAddress, calls: usize) {
    let mut span: CheatSpan = CheatSpan::Indefinite;
    if calls > 0 {
        span = CheatSpan::TargetCalls(calls);
    }
    cheat_caller_address(target, caller, span);
}

fn add_loanable_tokens(dispatcher: IPeerlendDispatcher) {
    let user_address: ContractAddress = 0xbeef.try_into().unwrap();
    prank_caller_address(dispatcher.contract_address, user_address, 1);

    let eth = contract_address_const::<eth_address>();
    let strk = contract_address_const::<strk_address>();
    let usdt = contract_address_const::<usdt_address>();
    let usdc = contract_address_const::<usdc_address>();

    let mut tokens: Array<ContractAddress> = ArrayTrait::new();
    tokens.append(eth);
    tokens.append(strk);
    tokens.append(usdt);
    tokens.append(usdc);

    let mut asset_id: Array<felt252> = ArrayTrait::new();
    asset_id.append('ETH/USD');
    asset_id.append('STRK/USD');
    asset_id.append('USDT/USD');
    asset_id.append('USDC/USD');

    dispatcher.set_loanable_tokens(tokens, asset_id);

    stop_cheat_caller_address(dispatcher.contract_address);
}

fn deposit_collateral(
    dispatcher: IPeerlendDispatcher, user: felt252, token: felt252, amount: u256, decimal: u32
) {
    let user_address: ContractAddress = user.try_into().unwrap();
    let token_address: ContractAddress = token.try_into().unwrap();

    cheat_caller_address_global(user_address);

    let token_amount: u256 = amount * fast_power(10, decimal.into());

    let token_dispatcher = ERC20ABIDispatcher { contract_address: token_address };
    token_dispatcher.approve(dispatcher.contract_address, token_amount);

    dispatcher.deposit_collateral(token_address, token_amount);

    stop_cheat_caller_address_global();
}
