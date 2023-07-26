module evently::ticket {

    use sui::object::{Self, UID, ID};
    use evently::event::{Self, Event};
    use sui::coin::{Self, Coin};
    use sui::tx_context::{Self, TxContext};
    use sui::sui::SUI;
    use sui::balance::{Self, Supply, Balance};
    use sui::transfer;
    use std::string;

    const NOT_ENOUGH_PAYMENT: u64 = 0;
    const NOT_PERMITTED: u64 = 1;
    const TICKET_SOLD_OUT: u64 = 2;
    const EVENT_TICKET_TYPE_MISMATCH: u64 = 3;

    struct EVENTLY has drop {}
    
    struct TicketType has key {
        id: UID,
        name: string::String,
        event_id: ID,
        price: u64,
        supply: Supply<EVENTLY>,
        balance: Balance<EVENTLY>
    }

    struct EventTicket has key, store {
        id: UID,
        ticket_type: ID,
    }

    public fun create_ticket(ctx: &mut TxContext, for_event: &Event, name: vector<u8>, price: u64, supply_value: u64) {
        // Check that the caller of the function is the owner of the event
        assert!(event::owner(for_event) == tx_context::sender(ctx), NOT_PERMITTED);
        
        let supply = balance::create_supply(EVENTLY {});
        let balance = balance::increase_supply(&mut supply, supply_value);

        let ticket_type = TicketType {
            id: object::new(ctx),
            name: string::utf8(name),
            event_id: event::event_id(for_event),
            price: price,
            supply: supply,
            balance: balance
        };
        transfer::share_object(ticket_type)
    }

    public fun mint(ctx: &mut TxContext, for_event: &mut Event, ticket_type: &mut TicketType, payment: Coin<SUI>) {
        // Check that the ticket_type is for the specified event
        assert!(event::event_id(for_event) == event_id(ticket_type), EVENT_TICKET_TYPE_MISMATCH);
        let coin_balance = coin::into_balance(payment);
        let taken_coin = coin::take(&mut coin_balance, ticket_type.price, ctx);
        let remainder = coin::from_balance(coin_balance, ctx);
        // Check that there is still supply for the ticket to be minted
        assert!(balance::value(&ticket_type.balance) != 0, TICKET_SOLD_OUT);
        let ticket = EventTicket {
            id: object::new(ctx),
            ticket_type: object::uid_to_inner(&ticket_type.id)
        };
        let sender = tx_context::sender(ctx);
        transfer::public_transfer(ticket, sender);
        let balance = coin::into_balance(taken_coin);
        event::increase_balance(for_event, balance);
        let to_decrease = balance::split(&mut ticket_type.balance, 1);
        balance::decrease_supply(&mut ticket_type.supply, to_decrease);
        transfer::public_transfer(remainder, sender);
    }

    public fun name(ticket_type: &TicketType): &string::String {
        return &ticket_type.name
    }

    public fun supply(ticket_type: &TicketType): u64 {
        balance::supply_value(&ticket_type.supply)
    }

    public fun balance(ticket_type: &TicketType): u64 {
        balance::value(&ticket_type.balance)
    }

    public fun price(ticket_type: &TicketType): u64 {
        ticket_type.price
    }

    public fun event_id(ticket_type: &TicketType): ID {
        ticket_type.event_id
    }

    public fun ticket_type_id(event_ticket: &EventTicket): ID {
        event_ticket.ticket_type
    }

    public fun id(ticket_type: &TicketType): ID {
        return object::uid_to_inner(&ticket_type.id)
    }

    public fun transfer(ticket: EventTicket, recipient: address) {
        transfer::public_transfer(ticket, recipient);
    }
}