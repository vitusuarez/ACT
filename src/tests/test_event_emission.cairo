#[cfg(test)]
mod tests {
    use core::debug::PrintTrait;
    use starknet::testing::{pop_log, set_contract_address};
    use dojo::model::{ModelStorage, ModelStorageTest};
    use dojo::world::WorldStorageTrait;

    use crate::types::direction::Direction;
    use crate::systems::actions::IActionsDispatcherTrait;
    use crate::tests::setup::tests as setup;
    
    // Use the event types directly from your contract
    use crate::systems::actions::actions::{Moved, Attacked};

    #[test]
    fn test_events() {
        // [Setup]
        let (world, systems, context) = setup::spawn_game();
        
        // Clear any existing logs
        let _ = starknet::testing::pop_log_raw(systems.actions.contract_address);
        
        // [Move]
        systems.actions.move(Direction::Up.into());
        
        // Check for emitted event
        let move_event = pop_log::<Moved>(systems.actions.contract_address).unwrap();
        assert(move_event.player == setup::PLAYER(), 'Wrong player in event');
        assert(move_event.direction == Direction::Up.into(), 'Wrong direction in event');
        
        // [Attack]
        systems.actions.attack();
        
        // Check for attack event
        let attack_event = pop_log::<Attacked>(systems.actions.contract_address).unwrap();
        assert(attack_event.player == setup::PLAYER(), 'Wrong player in attack event');
    }
}