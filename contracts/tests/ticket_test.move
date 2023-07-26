#[test_only]
module evently::ticket_test {

    use sui::test_scenario::Self;
    use evently::ticket::{Self, TicketType, EventTicket};
    use std::string;
    use std::vector;
    use sui::coin::{Self, Coin};
    use sui::transfer;
    use sui::sui::SUI;
    use evently::event::{Self, Event};

    const EVENT_CREATOR: address = @0xABCD;
    const DUMMY_ADDRESS: address = @0x10;
    const TICKET_MINTER: address = @0x20;
    const TRANSFER_RECIPIENT: address = @0x30;

    #[test]
    public fun create_ticket_test() {
        let scenario = test_scenario::begin(EVENT_CREATOR);
        // Create Event
        {
            event::create_event(b"Test Event", b"ipfs://quhvwyug", test_scenario::ctx(&mut scenario));
        };
        // Create Ticket [Success]
        test_scenario::next_tx(&mut scenario, EVENT_CREATOR);
        {
            let created_event = test_scenario::take_shared<Event>(&mut scenario);
            ticket::create_ticket(test_scenario::ctx(&mut scenario), &created_event, b"Test Ticket", 100, 10);
            test_scenario::return_shared(created_event)
        };
        // Check Ticket Details
        test_scenario::next_tx(&mut scenario, EVENT_CREATOR);
        {
            let created_ticket = test_scenario::take_shared<TicketType>(&mut scenario);
            assert!(*string::bytes(ticket::name(&created_ticket)) == b"Test Ticket", 0);
            assert!(ticket::supply(&created_ticket) == 10, 0);
            assert!(ticket::price(&created_ticket) == 100, 0);
            assert!(ticket::balance(&created_ticket) == 10, 0);
            test_scenario::return_shared(created_ticket);
        };
        test_scenario::end(scenario);
    }
    #[test]
    #[expected_failure(abort_code = evently::ticket::NOT_PERMITTED)]
    public fun create_ticket_not_permitted_test() {
        let scenario = test_scenario::begin(EVENT_CREATOR);
        // Create Event
        {
            event::create_event(b"Test Event", b"ipfs://quhvwyug", test_scenario::ctx(&mut scenario));
        };
        // Create Ticket [Fail]
        test_scenario::next_tx(&mut scenario, DUMMY_ADDRESS);
        {
            let created_event = test_scenario::take_shared<Event>(&mut scenario);
            ticket::create_ticket(test_scenario::ctx(&mut scenario), &created_event, b"Test Ticket", 100, 10);
            test_scenario::return_shared(created_event)
        };
        test_scenario::end(scenario);
    }
    #[test]
    public fun mint_ticket_test() {
        let scenario = test_scenario::begin(EVENT_CREATOR);
        // Create First Event
        {
            event::create_event(b"Test Event 1", b"ipfs://quhvwyug", test_scenario::ctx(&mut scenario));
        };
        // Create Ticket
        test_scenario::next_tx(&mut scenario, EVENT_CREATOR);
        {
            let created_event = test_scenario::take_shared<Event>(&mut scenario);
            ticket::create_ticket(test_scenario::ctx(&mut scenario), &created_event, b"Test Ticket", 10, 10);
            test_scenario::return_shared(created_event)
        };
        // Mint SUI Coin and transfer to TICKET_MINTER
        test_scenario::next_tx(&mut scenario, TICKET_MINTER);
        {
            let minted_coin = coin::mint_for_testing<SUI>(100, test_scenario::ctx(&mut scenario));
            transfer::public_transfer(minted_coin, TICKET_MINTER);
        };
        // Mint Ticket 
        test_scenario::next_tx(&mut scenario, TICKET_MINTER);
        {
            let payment = test_scenario::take_from_sender<Coin<SUI>>(&mut scenario);
            let ticket_type = test_scenario::take_shared<TicketType>(&mut scenario);
            let created_event = test_scenario::take_shared<Event>(&mut scenario);
            ticket::mint(test_scenario::ctx(&mut scenario), &mut created_event, &mut ticket_type, payment);
            test_scenario::return_shared(ticket_type);
            test_scenario::return_shared(created_event)
        };
        // Verify After Mint Effects
        // 1. Sender SUI Balance should have decreased by the price of ticket bought
        // 2. TicketType Balance and supply should have reduced by the amount of EventTicket minted
        // 3. Event should have more sui balance (equal to the value of the minted coins)
        // 4. Sender should now have a owned EventTicket
        test_scenario::next_tx(&mut scenario, TICKET_MINTER);
        {
            let remainder = test_scenario::take_from_sender<Coin<SUI>>(&mut scenario);
            let ticket_type = test_scenario::take_shared<TicketType>(&mut scenario);
            let created_event = test_scenario::take_shared<Event>(&mut scenario);
            let user_tickets = test_scenario::ids_for_sender<EventTicket>(&scenario);
            let minted_ticket = test_scenario::take_from_sender<EventTicket>(&mut scenario);
            assert!(coin::value(&remainder) == 90, 0);
            assert!(ticket::balance(&ticket_type) == 9, 0);
            assert!(ticket::supply(&ticket_type) == 9, 0);
            assert!(event::balance(&created_event) == 10, 0);
            assert!(ticket::ticket_type_id(&minted_ticket) == ticket::id(&ticket_type), 0);
            assert!(vector::length(&user_tickets) == 1, 0);
            test_scenario::return_to_sender(&scenario, remainder);
            test_scenario::return_to_sender(&scenario, minted_ticket);
            test_scenario::return_shared(ticket_type);
            test_scenario::return_shared(created_event);
        };
        test_scenario::end(scenario);
    }
    #[test]
    #[expected_failure(abort_code = evently::ticket::TICKET_SOLD_OUT)]
    public fun mint_sold_out_ticket() {
        let scenario = test_scenario::begin(EVENT_CREATOR);
        // Create Event
        {
            event::create_event(b"Test Event", b"ipfs://quhvwyug", test_scenario::ctx(&mut scenario));
        };
        // Create Ticket
        test_scenario::next_tx(&mut scenario, EVENT_CREATOR);
        {
            let created_event = test_scenario::take_shared<Event>(&mut scenario);
            ticket::create_ticket(test_scenario::ctx(&mut scenario), &created_event, b"Test Ticket", 10, 1);
            test_scenario::return_shared(created_event)
        };
        // Mint SUI Coin and transfer to TICKET_MINTER
        test_scenario::next_tx(&mut scenario, TICKET_MINTER);
        {
            let minted_coin = coin::mint_for_testing<SUI>(100, test_scenario::ctx(&mut scenario));
            transfer::public_transfer(minted_coin, TICKET_MINTER);
        };
        // Mint Ticket 
        test_scenario::next_tx(&mut scenario, TICKET_MINTER);
        {
            let payment = test_scenario::take_from_sender<Coin<SUI>>(&mut scenario);
            let ticket_type = test_scenario::take_shared<TicketType>(&mut scenario);
            let created_event = test_scenario::take_shared<Event>(&mut scenario);
            ticket::mint(test_scenario::ctx(&mut scenario), &mut created_event, &mut ticket_type, payment);
            test_scenario::return_shared(ticket_type);
            test_scenario::return_shared(created_event);
        };
        // Mint Ticket Again
        test_scenario::next_tx(&mut scenario, TICKET_MINTER);
        {
            let payment = test_scenario::take_from_sender<Coin<SUI>>(&mut scenario);
            let ticket_type = test_scenario::take_shared<TicketType>(&mut scenario);
            let created_event = test_scenario::take_shared<Event>(&mut scenario);
            ticket::mint(test_scenario::ctx(&mut scenario), &mut created_event, &mut ticket_type, payment);
            test_scenario::return_shared(ticket_type);
            test_scenario::return_shared(created_event);
        };
        test_scenario::end(scenario);
    }
    #[test]
    #[expected_failure(abort_code = evently::ticket::EVENT_TICKET_TYPE_MISMATCH)]
    public fun mint_event_ticket_type_mismatch() {
        let scenario = test_scenario::begin(EVENT_CREATOR);
        // Create First Event
        {
            event::create_event(b"Test Event 1", b"ipfs://quhvwyug", test_scenario::ctx(&mut scenario));
        };
        test_scenario::next_tx(&mut scenario, EVENT_CREATOR);
        // Create Second Event
        {
            event::create_event(b"Test Event 2", b"ipfs://quhvwyuh", test_scenario::ctx(&mut scenario));
        };
        // Create Ticket For First Event
        test_scenario::next_tx(&mut scenario, EVENT_CREATOR);
        {
            let created_event_second = test_scenario::take_shared<Event>(&mut scenario);
            let created_event_first = test_scenario::take_shared<Event>(&mut scenario);
            ticket::create_ticket(test_scenario::ctx(&mut scenario), &created_event_first, b"Test Ticket", 10, 10);
            test_scenario::return_shared(created_event_first);
            test_scenario::return_shared(created_event_second)
        };
        // Mint SUI Coin and transfer to TICKET_MINTER
        test_scenario::next_tx(&mut scenario, TICKET_MINTER);
        {
            let minted_coin = coin::mint_for_testing<SUI>(100, test_scenario::ctx(&mut scenario));
            transfer::public_transfer(minted_coin, TICKET_MINTER);
        };
        // Mint Ticket for Second Event [This should raise an Error]
        test_scenario::next_tx(&mut scenario, TICKET_MINTER);
        {
            let payment = test_scenario::take_from_sender<Coin<SUI>>(&mut scenario);
            let ticket_type = test_scenario::take_shared<TicketType>(&mut scenario);
            let created_event_second = test_scenario::take_shared<Event>(&mut scenario);
            let created_event_first = test_scenario::take_shared<Event>(&mut scenario);
            ticket::mint(test_scenario::ctx(&mut scenario), &mut created_event_second, &mut ticket_type, payment);
            test_scenario::return_shared(ticket_type);
            test_scenario::return_shared(created_event_first);
            test_scenario::return_shared(created_event_second)
        };
        test_scenario::end(scenario);
    }
}