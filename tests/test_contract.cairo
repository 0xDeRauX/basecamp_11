// basecamp_11 session 3

// local dependance
use basecamp_11::Counter;
use basecamp_11::{
    ICounterDispatcher, ICounterDispatcherTrait, ICounterSafeDispatcher,
    ICounterSafeDispatcherTrait,
};

// dependance externe
use starknet::ContractAddress;
use snforge_std::{
    declare, ContractClassTrait, DeclareResultTrait, start_cheat_caller_address,
    stop_cheat_caller_address, spy_events, EventSpyAssertionsTrait,
};

fn OWNER() -> ContractAddress {
    'OWNER'.try_into().unwrap()
}
    
fn deploy_contract_counter(initial_count: u32) -> (ICounterDispatcher, ICounterSafeDispatcher) {
     // déclare le contrat "Counter" et extrait la classe du contrat, ce qui est nécessaire pour le déployer.
    let contract = declare("Counter").unwrap().contract_class();

    // On récupére les donner du contract et du Counter initial sous forme 
    // serialize the calldata
    let mut calldata = array! [] ;
    initial_count.serialize(ref calldata);
    OWNER().serialize(ref calldata);

    // contrat est déployé en utilisant les données sérialisées dans calldata
    let (contract_address, _) = contract.deploy(@calldata).unwrap();
    
    let dispatcher = ICounterDispatcher { contract_address };
    let safe_disptacher = ICounterSafeDispatcher { contract_address };
    (dispatcher, safe_disptacher)
}

#[test]
fn test_deploy_contract() {
    let initial_count = 0;
    let (counter, _) = deploy_contract_counter(initial_count) ;
    
    let current_counter = counter.get_counter () ;
    assert!(current_counter == initial_count, "count should be initial count")

}

#[test]
fn test_increase_counter() {
    let initial_counter = 0;
    let (counter, _) = deploy_contract_counter(initial_counter);
    
    counter.increase_counter();

    let expected_counter = initial_counter + 1;
    let courrent_counter = counter.get_counter();

    assert!(courrent_counter == expected_counter, "Counter should increment")
}

#[test]
fn test_decrease_counter() {
    let initial_counter = 1;
    let (counter, _) = deploy_contract_counter(initial_counter);
    
    counter.decrease_counter();

    let expected_counter = initial_counter - 1;
    let courrent_counter = counter.get_counter();

    assert!(courrent_counter == expected_counter, "Counter should decrease")
}

#[test]
#[feature("safe_disptacher")]
fn test_decrease_counter_underflow(){
    let initial_counter = 0;
    let (_, safe_counter) = deploy_contract_counter(initial_counter); // Déploiement du contrat "Counter" avec initial_count = 0

    // Tentative de décrémenter le compteur
    match safe_counter.decrease_counter() {
        Result::Ok(_) => panic!("Decrease below 0 did not panic"), // Si la décrémentation réussit, c'est une erreur (puisque le compteur est à 0)
        Result::Err(panic_data) => {
            // Si une erreur se produit, elle devrait être liée à une panique, vérifier le message d'erreur
            assert!(
                *panic_data[0] == 'Counter can\'t be negative', // Vérifie que le message d'erreur est celui attendu pour l'underflow
                "Should throw NEGATIVE COUNTER error",  // Si ce n'est pas le bon message, échoue le test avec ce message
            )
        },
    }
}

#[test]
#[should_panic]
fn test_increase_counter_overflow() {
    let initial_count = 0xFFFFFFFF;
    let (counter, _) = deploy_contract_counter(initial_count);
    counter.increase_counter();
}

#[test]
#[feature("safe_dispatcher")]
fn test_reset_counter_non() {
    let initial_counter = 5;
    let (counter, safe_counter) = deploy_contract_counter(initial_counter);

    match safe_counter.reset_counter() {
        Result::Ok(_) => panic!("non-owner cannot reset the counter"),
        Result::Err(panic_data) => {
            assert!(
                *panic_data[0] == 'Caller is not the owner',
                "Should error if calle",
            )
        },
    }

    let current_counter = counter.get_counter();
    assert!(current_counter == initial_counter, "Counter should not have reset")
}

#[test]
#[feature("safe_dispatcher")]
fn test_reset_counter_as_owner() {
    let initial_counter = 5;
    let (counter, safe_counter) = deploy_contract_counter(initial_counter);

    counter.increase_counter() ;

    start_cheat_caller_address(counter.contract_address, OWNER());
    counter.reset_counter();
    stop_cheat_caller_address(counter.contract_address) ;

    let current_counter = counter.get_counter();
    assert!(current_counter == 0, "Counter should be reset to 0")
}

#[test]
fn test_increase_counter_with_event() {
    let initial_counter = 0;
    let (counter, _) = deploy_contract_counter(initial_counter);
    let mut spy = spy_events();

    counter.increase_counter();

    let expected_counter = initial_counter + 1;
    let current_counter = counter.get_counter() ;

    spy
        .assert_emitted(
            @array![
                (
                    counter.contract_address,
                    Counter::Event::CounterIncreased(
                        Counter::CounterIncreased { counter: current_counter }
                    ),
                ),
            ],
        );

    assert!(current_counter == expected_counter, "Counter should increment")
}

#[test]
fn test_decrease_counter_with_event() {
    let initial_counter = 5;
    let (counter, _) = deploy_contract_counter(initial_counter);
    let mut spy = spy_events();

    counter.decrease_counter();

    let expected_counter = initial_counter - 1;
    let current_counter = counter.get_counter() ;

    spy
        .assert_emitted(
            @array![
                (
                    counter.contract_address,
                    Counter::Event::CounterDecreased(
                        Counter::CounterDecreased { counter: current_counter }
                    ),
                ),
            ],
        );

    assert!(current_counter == expected_counter, "Counter should decrement")
}