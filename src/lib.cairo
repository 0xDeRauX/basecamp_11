#[starknet::interface]
pub trait ICounter<T> {
    fn get_counter(self: @T) -> u32;
    fn increase_counter(ref self: T);
    fn decrease_counter(ref self: T);
    fn reset_counter(ref self: T);
}

#[starknet::contract]
pub mod Counter {
    use super::ICounter;
    use starknet::ContractAddress;
    use openzeppelin_access::ownable::OwnableComponent;
    use starknet::storage::{StoragePointerReadAccess, StoragePointerWriteAccess};

    component!(path: OwnableComponent, storage: ownable, event: OwnableEvent);

    // Ownable Mixin
    #[abi(embed_v0)]
    impl OwnableMixinImpl = OwnableComponent::OwnableMixinImpl<ContractState>;
    impl InternalImpl = OwnableComponent::InternalImpl<ContractState>;

    #[storage]
    struct Storage {
        counter: u32,
        #[substorage(v0)]
        ownable: OwnableComponent::Storage
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    pub enum Event {
        CounterIncreased: CounterIncreased,
        CounterDecreased: CounterDecreased,
        #[flat]
        OwnableEvent: OwnableComponent::Event
    }

    #[derive(Drop, starknet::Event)]
    pub struct CounterIncreased {
        pub counter: u32
    }
    
    #[derive(Drop, starknet::Event)]
    pub struct CounterDecreased {
        pub counter: u32
    }

    pub mod Errors {
        pub const Negative_counter_value: felt252 = 'Counter can\'t be negative';
    }

    #[constructor]
    fn constructor(ref self: ContractState, init_value: u32, owner: ContractAddress) {
        self.counter.write(init_value);
        self.ownable.initializer(owner);
    }

    #[abi(embed_v0)]
    impl CounterImpl of ICounter<ContractState> {
        fn get_counter(self: @ContractState) -> u32 {
            self.counter.read()
        }

        fn increase_counter(ref self: ContractState) {
            let actual_counter = self.counter.read();
            let new_counter = actual_counter + 1;
            self.counter.write(new_counter);
            self.emit(CounterIncreased { counter: new_counter });
        }

        fn decrease_counter(ref self: ContractState) {
            let actual_counter = self.counter.read();
            assert(actual_counter > 0, 'Counter can\'t be negative');
            let new_counter = actual_counter - 1;
            self.counter.write(new_counter);
            self.emit(CounterDecreased { counter: new_counter });
        }

        fn reset_counter(ref self: ContractState) {
            self.counter.write(0);
        }
    }
}

// sh
// starkli signer keystore new keystore.json
// starkli account oz init account.json --keystore keystore.json
// starkli account deploy account.json --keystore keystore.json
// starkli declare /workspaces/basecamp_11/target/dev/basecamp_11_Counter.contract_class.json --account account.json --keystore keystore.json
// 0x051135004cdefce743598b68e8181676949659ea3ca52732ee28da029d9532d6