use core::option::OptionTrait;
use starknet::{ContractAddress, contract_address_const};

use snforge_std::{
    declare, ContractClassTrait, spy_events, SpyOn, EventSpy, EventAssertions, CheatSpan,
    cheat_caller_address
};

use core::num::traits::Zero;

use openzeppelin::access::ownable::interface::IOwnable;
use openzeppelin::access::ownable::interface::IOwnableDispatcher;

use peerlend::protocol::IPeerlendSafeDispatcher;
use peerlend::protocol::IPeerlendSafeDispatcherTrait;
use peerlend::protocol::IPeerlendDispatcher;
use peerlend::protocol::IPeerlendDispatcherTrait;

use openzeppelin::token::erc20::interface::IERC20Dispatcher;
use openzeppelin::token::erc20::interface::IERC20DispatcherTrait;

use alexandria_math::fast_power::fast_power;


const eth_strk_holder: felt252 = 0x0213c67ed78bc280887234fe5ed5e77272465317978ae86c25a71531d9332a2d;
const usdt_holder: felt252 = 0x02c4cae26ffd948639154cc2baa91f48c1e7a39b7a456a473f4f17d2ade96877;
const usdc_holder: felt252 = 0x01c27cb555fdb7704d63c4b7ca7e5dfa1bc73872e762896e77b64d08235a821d;

const strk_address: felt252 = 0x04718f5a0fc34cc1af16a1cdee98ffb20c31f5cd61d6ab07201858f4287c938d;
const eth_address: felt252 = 0x049d36570d4e46f48e99674bd3fcc84644ddd6b96f7c741b1562b82f9e004dc7;
const usdt_address: felt252 = 0x068f5c6a61780768455de69077e07e89787839bf8166decfbf92b645209c0fb8;
const usdc_address: felt252 = 0x053c91253bc9682c04929ca02ed00b3e423f6710d2ee7e0d5ebb06f3ecf368a8;

fn deploy_contract(name: ByteArray) -> ContractAddress {
    let owner: ContractAddress = 0xbeef.try_into().unwrap();
    let contract = declare(name).unwrap();
    let calldata: Array<felt252> = array![owner.into()];
    let (contract_address, _) = contract.deploy(@calldata).unwrap();
    contract_address
}

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
    let user_details = dispatcher.get_user_details(user_address);

    assert(user_details.address == Zero::zero(), 'Invalid borrower');
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
    tokens.append('deed'.try_into().unwrap());
    tokens.append('dead'.try_into().unwrap());
    tokens.append('deaf'.try_into().unwrap());

    dispatcher.set_loanable_tokens(tokens);

    assert(dispatcher.get_collateral_token_id() == 3, 'Invalid collateral token id');
}

#[test]
#[fork("mainnet")]
fn test_deposit_collateral() {
    let contract_address = deploy_contract("Peerlend");

    let dispatcher = IPeerlendDispatcher { contract_address };
    add_loanable_tokens(dispatcher);
    let user_address: ContractAddress = usdc_holder.try_into().unwrap();
    let usdc = contract_address_const::<usdc_address>();

    prank_caller_address(contract_address, user_address, 10);

    let usdc_amount: u256 = 1000 * fast_power(10, 6);
    println!("eth_amount: {}", usdc_amount);

    let usdc_dispatcher = IERC20Dispatcher { contract_address: usdc };
    usdc_dispatcher.approve(dispatcher.contract_address, usdc_amount);

    dispatcher.deposit_collateral(usdc, usdc_amount);

    assert(dispatcher.get_collateral_deposited(usdc) == usdc_amount, 'Invalid usdc balance');
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
    let usdt = contract_address_const::<usdt_address>();
    let usdc = contract_address_const::<usdc_address>();

    let mut tokens: Array<ContractAddress> = ArrayTrait::new();
    tokens.append(eth);
    tokens.append(usdt);
    tokens.append(usdc);

    dispatcher.set_loanable_tokens(tokens);
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


