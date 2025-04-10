#[cfg(test)]
mod tests {
    use starknet::{ContractAddress, contract_address_const};
    use dojo::test_utils::{spawn_test_world, deploy_contract};
    use dojo::world::{IWorldDispatcher, IWorldDispatcherTrait};

    // Import actions system and interface directly
    use crate::systems::actions::actions;
    
    // Re-export the interface from systems module
    use crate::systems::actions::{IActionsDispatcher, IActionsDispatcherTrait};
    
    // Import model types
    use crate::types::role::Role;
    use crate::types::direction::Direction;
    use crate::models::index::{Player, Dungeon};
    
    // Test constants
    pub fn PLAYER() -> ContractAddress {
        contract_address_const::<0x1>()
    }
    pub const PLAYER_NAME: felt252 = 'PLAYER';
    
    /// Helper to set up a test world and deploy the actions contract
    pub fn spawn_game() -> (IWorldDispatcher, IActionsDispatcher, ContractAddress) {
        // Create test world
        let world = spawn_test_world();
        
        // Deploy actions contract
        let contract_address = deploy_contract(world, actions::TEST_CLASS_HASH, array![]);
        let actions = IActionsDispatcher { contract_address };
        
        // Set caller as player
        starknet::testing::set_contract_address(PLAYER());
        starknet::testing::set_caller_address(PLAYER());
        
        // Spawn player
        actions.spawn(PLAYER_NAME, Role::Water);
        
        // Return world, actions dispatcher, and player address
        (world, actions, PLAYER())
    }
}