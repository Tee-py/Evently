module evently::event {

    use sui::object::{Self, UID, ID};
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};
    use sui::balance::{Self, Balance};
    use sui::event;
    use sui::coin;
    use sui::sui::SUI;
    use std::string;

    friend evently::ticket;
    friend evently::event_tests;

    const NOT_PERMITTED: u64 = 1;


    struct Event has key {
        id: UID,
        name: string::String,
        owner: address,
        metadata_uri: string::String,
        balance: Balance<SUI>
    }

    struct CreateEvent has copy, drop {
        event_id: ID,
        creator: address,
    }

    public fun create_event(name: vector<u8>, metadata_uri: vector<u8>, ctx: &mut TxContext) {
        let event = Event {
            id: object::new(ctx),
            name: string::utf8(name),
            owner: tx_context::sender(ctx),
            metadata_uri: string::utf8(metadata_uri),
            balance: balance::zero<SUI>()
        };
        event::emit(CreateEvent {
            event_id: object::uid_to_inner(&event.id),
            creator: tx_context::sender(ctx)
        });
        transfer::share_object(event);
    }

    public fun withdraw_profits(ctx: &mut TxContext, event: &mut Event, amount: u64){
        assert!(event.owner == tx_context::sender(ctx), NOT_PERMITTED);
        let profit = coin::from_balance(balance::split(&mut event.balance, amount), ctx);
        transfer::public_transfer(profit, tx_context::sender(ctx));
    }

    // Public accessor method to event's name
    public fun name(event: &Event): &string::String {
        &event.name
    }

    // Public accessor method to metadata_uri
    public fun metadata(event: &Event): &string::String {
        &event.metadata_uri
    }

    // Public accessor method to event id
    public fun event_id(event: &Event): ID {
        return object::uid_to_inner(&event.id)
    }

    // Public accessor method to event owner address
    public fun owner(event: &Event): address {
        return event.owner
    }

    // Public accessor method to event balance
    public fun balance(event: &Event): u64 {
        return balance::value(&event.balance)
    }

    public(friend) fun increase_balance(event: &mut Event, balance: Balance<SUI>) {
        balance::join(&mut event.balance, balance);
    }
}