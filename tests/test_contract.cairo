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
    
#[test]
fn test_deploy_contract(){
    // déclare le contrat "Counter" et extrait la classe du contrat, ce qui est nécessaire pour le déployer.
    let contract = declare("Counter") .unwrap() .contract_class();
    
    // serialize the calldata
    // On récupére les donner du contract et du Counter initial sous forme 
    let mut calldata = array![];
    let inititial_count = 0;
    inititial_count.serialize(ref calldata);
    OWNER().serialize(ref calldata);

    // contrat est déployé en utilisant les données sérialisées dans calldata
    let (contract_address, _) = contract.deploy(@calldata).unwrap();

}