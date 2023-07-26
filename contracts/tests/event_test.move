#[test_only]
module evently::event_tests {
    use sui::coin::{Self, Coin};
    use sui::sui::SUI;
    use sui::test_scenario::Self;
    use std::string;

    use evently::event::{Self, Event};

    const EVENT_CREATOR: address = @0xABCD;
    const DUMMY_ADDRESS: address = @0x10;

    #[test]
    fun create_event_test() {
        let scenario_val = test_scenario::begin(EVENT_CREATOR);
        let scenario = &mut scenario_val;
        // Create Event
        {
            event::create_event(b"Test Event", b"ipfs://quhvwyug", test_scenario::ctx(scenario));
        };
        // Get Created Event and Check the properties
        test_scenario::next_tx(scenario, EVENT_CREATOR);
        {
            let created_event = test_scenario::take_shared<Event>(scenario);
            assert!(*string::bytes(event::name(&created_event)) == b"Test Event", 0);
            assert!(*string::bytes(event::metadata(&created_event)) == b"ipfs://quhvwyug", 0);
            assert!(event::owner(&created_event) == EVENT_CREATOR, 0);
            assert!(event::balance(&created_event) == 0, 0);
            test_scenario::return_shared(created_event);
        };
        test_scenario::end(scenario_val);
    }

    #[test]
    fun withdraw_profits_test() {
        let scenario = test_scenario::begin(EVENT_CREATOR);
        // Create Event
        {
            event::create_event(b"Test Event", b"ipfs://quhvwyug", test_scenario::ctx(&mut scenario));
        };
        // Increase Event Balance
        test_scenario::next_tx(&mut scenario, EVENT_CREATOR);
        {
            let created_event = test_scenario::take_shared<Event>(&mut scenario);
            let coin = coin::mint_for_testing<SUI>(10, test_scenario::ctx(&mut scenario));
            let bal = coin::into_balance(coin);
            event::increase_balance(&mut created_event, bal);
            assert!(event::balance(&created_event) == 10, 0);
            test_scenario::return_shared(created_event);
        };
        // Withdraw Profits
        test_scenario::next_tx(&mut scenario, EVENT_CREATOR);
        {
            let created_event = test_scenario::take_shared<Event>(&mut scenario);
            event::withdraw_profits(test_scenario::ctx(&mut scenario), &mut created_event, 5);
            test_scenario::return_shared(created_event);
        };
        // Check EVENT_CREATOR coin balance
        test_scenario::next_tx(&mut scenario, EVENT_CREATOR);
        {
            let sender_coin = test_scenario::take_from_sender<Coin<SUI>>(&mut scenario);
            assert!(coin::value(&sender_coin) == 5, 0);
            test_scenario::return_to_sender(&mut scenario, sender_coin);
        };
        test_scenario::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = evently::event::NOT_PERMITTED)]
    fun withdraw_profits_not_permitted_test() {
        let scenario = test_scenario::begin(EVENT_CREATOR);
        // Create Event
        {
            event::create_event(b"Test Event", b"ipfs://quhvwyug", test_scenario::ctx(&mut scenario));
        };
        // Withdraw Profits
        test_scenario::next_tx(&mut scenario, DUMMY_ADDRESS);
        {
            let created_event = test_scenario::take_shared<Event>(&mut scenario);
            event::withdraw_profits(test_scenario::ctx(&mut scenario), &mut created_event, 5);
            test_scenario::return_shared(created_event);
        };
        test_scenario::end(scenario);
    }
}