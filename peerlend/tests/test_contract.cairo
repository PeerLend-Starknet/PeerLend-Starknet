use starknet::{ContractAddress, contract_address_const};

use snforge_std::{declare, ContractClassTrait, spy_events, SpyOn, EventSpy, EventAssertions};

use core::num::traits::Zero;

use openzeppelin::access::ownable::interface::IOwnable;
use openzeppelin::access::ownable::interface::IOwnableDispatcher;

use peerlend::protocol::IPeerlendSafeDispatcher;
use peerlend::protocol::IPeerlendSafeDispatcherTrait;
use peerlend::protocol::IPeerlendDispatcher;
use peerlend::protocol::IPeerlendDispatcherTrait;

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

    let user_address = 0xdeadbeef.try_into().unwrap();
    let user_details = dispatcher.get_user_details(user_address);

    assert(user_details.address == Zero::zero(), 'Invalid borrower');
    assert(user_details.total_amount_borrowed == 0, 'Invalid lender');
    assert(user_details.total_amount_repaid == 0, 'Invalid amount repaid');
    assert(user_details.total_amount_lended == 0, 'Invalid amount lended');
    assert(user_details.current_loan == 0, 'Invalid lender balance');
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


