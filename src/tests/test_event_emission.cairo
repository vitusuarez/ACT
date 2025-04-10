#[cfg(test)]
mod tests {
    use core::debug::PrintTrait;
    use starknet::testing::{pop_log, set_contract_address};
    use dojo::model::{ModelStorage, ModelStorageTest};
    use dojo::world::WorldStorageTrait;

    use crate::types::direction::Direction;
    use crate::types::role::Role;
    use crate::types::monster::Monster;
    use crate::systems::actions::IActionsDispatcherTrait;
    use crate::tests::setup::tests as setup;
    
    // Use the event types from updated contracts
    use crate::systems::actions::actions::{Moved, Attacked, Healed, Spawned};

    /// Tests that spawning emits correct events
    #[test]
    fn test_spawn_event() {
        // [Setup] Create test environment
        let (world, systems, _) = setup::spawn_game();
        
        // Clear previous logs
        let _ = starknet::testing::pop_log_raw(systems.actions.contract_address);
        
        // [Spawn] New player
        let test_address = starknet::contract_address_const::<'TEST_USER'>();
        set_contract_address(test_address);
        systems.actions.spawn('TEST_PLAYER', Role::Fire);
        
        // Check spawn event
        let spawn_event = pop_log::<Spawned>(systems.actions.contract_address).unwrap();
        assert(spawn_event.player == test_address, 'Wrong player in spawn event');
        assert(spawn_event.name == 'TEST_PLAYER', 'Wrong name in spawn event');
        assert(spawn_event.role == Role::Fire.into(), 'Wrong role in spawn event');
        assert(spawn_event.initial_health > 0, 'Health not set in spawn event');
        assert(spawn_event.initial_damage > 0, 'Damage not set in spawn event');
    }
    
    /// Tests that movement emits correct events
    #[test]
    fn test_move_event() {
        // [Setup] Create test environment
        let (world, systems, context) = setup::spawn_game();
        
        // Clear previous logs
        let _ = starknet::testing::pop_log_raw(systems.actions.contract_address);
        
        // [Move] Up
        systems.actions.move(Direction::Up);
        
        // Check move event
        let move_event = pop_log::<Moved>(systems.actions.contract_address).unwrap();
        assert(move_event.player == setup::PLAYER(), 'Wrong player in move event');
        assert(move_event.direction == Direction::Up.into(), 'Wrong direction in move event');
        assert(move_event.generated_monster > 0, 'No monster in move event');
        assert(move_event.generated_role > 0, 'No role in move event'); 
    }
    
    /// Tests that attacking emits correct events
    #[test]
    fn test_attack_event() {
        // [Setup] Create test environment
        let (world, systems, context) = setup::spawn_game();
        let world_state = world.world_state();
        
        // [Setup] Generate dungeon with monster
        systems.actions.move(Direction::Up);
        
        // Clear previous logs
        let _ = starknet::testing::pop_log_raw(systems.actions.contract_address);
        
        // [Attack]
        systems.actions.attack();
        
        // Check attack event
        let attack_event = pop_log::<Attacked>(systems.actions.contract_address).unwrap();
        assert(attack_event.player == setup::PLAYER(), 'Wrong player in attack event');
        assert(attack_event.damage_dealt > 0, 'No damage in attack event');
        assert(attack_event.player_health > 0, 'No player health in attack event');
    }
    
    /// Tests that healing emits correct events
    #[test]
    fn test_heal_event() {
        // [Setup] Create test environment
        let (world, systems, context) = setup::spawn_game();
        let mut world_state = world.world_state();
        
        // [Setup] Move to generate initial gold and create shop
        systems.actions.move(Direction::Up);
        
        // Defeat monster to get gold
        loop {
            let dungeon: crate::models::index::Dungeon = 
                world_state.model_storage.read(context.player_id);
            if dungeon.health == 0 {
                break;
            }
            systems.actions.attack();
        }
        
        // Create shop dungeon
        systems.actions.move(Direction::Up);
        let mut dungeon: crate::models::index::Dungeon = 
            world_state.model_storage.read(context.player_id);
        dungeon.monster = Monster::None.into();
        world_state.model_storage.write(context.player_id, dungeon);
        
        // Damage player
        let mut player: crate::models::index::Player = 
            world_state.model_storage.read(context.player_id);
        player.health = 50; // Set to half health
        world_state.model_storage.write(context.player_id, player);
        
        // Clear previous logs
        let _ = starknet::testing::pop_log_raw(systems.actions.contract_address);
        
        // [Heal]
        systems.actions.heal(1);
        
        // Check heal event
        let heal_event = pop_log::<Healed>(systems.actions.contract_address).unwrap();
        assert(heal_event.player == setup::PLAYER(), 'Wrong player in heal event');
        assert(heal_event.quantity == 1, 'Wrong quantity in heal event');
        assert(heal_event.new_health > 50, 'Health not increased in heal event');
        assert(heal_event.gold_spent > 0, 'No gold spent in heal event');
    }
    
    /// Tests full gameplay flow events
    #[test]
    fn test_full_gameplay_events() {
        // [Setup] Create test environment
        let (world, systems, context) = setup::spawn_game();
        let world_state = world.world_state();
        
        // Clear previous logs
        let _ = starknet::testing::pop_log_raw(systems.actions.contract_address);
        
        // [Move] to generate dungeon
        systems.actions.move(Direction::Up);
        let move_event = pop_log::<Moved>(systems.actions.contract_address).unwrap();
        
        // [Attack] to defeat monster
        while true {
            let dungeon: crate::models::index::Dungeon = 
                world_state.model_storage.read(context.player_id);
            if dungeon.health == 0 {
                break;
            }
            
            systems.actions.attack();
            let _ = pop_log::<Attacked>(systems.actions.contract_address);
        }
        
        // [Move] to generate shop
        systems.actions.move(Direction::Right);
        let move_event2 = pop_log::<Moved>(systems.actions.contract_address).unwrap();
        
        // For shop movement, alter the monster type
        let mut dungeon: crate::models::index::Dungeon = 
            world_state.model_storage.write_mut(context.player_id);
        dungeon.monster = Monster::None.into();
        
        // [Heal]
        systems.actions.heal(1);
        let heal_event = pop_log::<Healed>(systems.actions.contract_address).unwrap();
        
        // Log check - make sure we got all expected events
        assert(move_event.direction == Direction::Up.into(), 'First move event missing');
        assert(move_event2.direction == Direction::Right.into(), 'Second move event missing');
        assert(heal_event.quantity == 1, 'Heal event missing');
    }
}