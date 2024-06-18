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
    let owner = contract_address_const < 'beef' > ();
    let contract = declare(name).unwrap();
    let calldata: Array<felt252> = array![owner];
    let (contract_address, _) = contract.deploy(@calldata).unwrap();
    contract_address
}

#[test]
fn test_deployment() {
    let contract_address = deploy_contract("Peerlend");

    let dispatcher = IOwnableDispatcher { contract_address: contract_address };

    let owner: ContractAddress = dispatcher.owner();
    assert(owner != Zero::zero(), 'Invalid owner');
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


