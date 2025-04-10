#[cfg(test)]
mod tests {
    use core::debug::PrintTrait;
    use starknet::testing::set_contract_address;
    use dojo::model::{ModelStorage, ModelStorageTest};
    use dojo::world::WorldStorageTrait;

    use crate::models::index::{Player, Dungeon};
    use crate::types::direction::Direction;
    use crate::types::monster::Monster;
    use crate::constants::{DEFAULT_POTION_COST, DEFAULT_POTION_HEAL};
    use crate::systems::actions::IActionsDispatcherTrait;
    use crate::tests::setup::tests as setup;

    /// Tests healing functionality in shop dungeon
    #[test]
    fn test_actions_heal() {
        // [Setup] Create test environment with injured player and gold
        let (world, systems, context) = setup::spawn_game();
        let mut world_state = world.world_state();

        // [Setup] Generate monster, defeat it to earn gold, then take some damage
        systems.actions.move(Direction::Up);
        
        // Attack until almost dead to ensure we have damage to heal
        loop {
            let player: Player = world_state.model_storage.read::<Player>(context.player_id);
            let dungeon: Dungeon = world_state.model_storage.read::<Dungeon>(context.player_id);
            
            // If monster dead or player health too low, break
            if dungeon.health == 0 || player.health < 50 {
                break;
            }
            systems.actions.attack();
        }
        
        // Ensure monster is defeated
        loop {
            let dungeon: Dungeon = world_state.model_storage.read::<Dungeon>(context.player_id);
            if dungeon.health == 0 {
                break;
            }
            systems.actions.attack();
        }

        // [Move] To generate a new empty dungeon (shop)
        systems.actions.move(Direction::Up);
        
        // Modify the dungeon to be a shop (monster = 0)
        let mut dungeon: Dungeon = world_state.model_storage.read::<Dungeon>(context.player_id);
        dungeon.monster = Monster::None.into();
        world_state.model_storage.write(context.player_id, dungeon);

        // Record player state before healing
        let player: Player = world_state.model_storage.read::<Player>(context.player_id);
        let player_health_before = player.health;
        let player_gold_before = player.gold;
        
        // [Heal] with 1 potion
        systems.actions.heal(1);

        // [Assert] Player health should increase and gold should decrease
        let player_after: Player = world_state.model_storage.read::<Player>(context.player_id);
        
        // Health should increase by healing amount
        assert(
            player_after.health == player_health_before + DEFAULT_POTION_HEAL, 
            'Heal: player health should increase'
        );
        
        // Gold should decrease by potion cost
        assert(
            player_after.gold == player_gold_before - DEFAULT_POTION_COST, 
            'Heal: player gold should decrease'
        );
    }
    
    /// Tests healing fails if player doesn't have enough gold
    #[test]
    #[should_panic(expected: ('Player: not enough gold',))]
    fn test_heal_fails_without_gold() {
        // [Setup] Create test environment
        let (world, systems, context) = setup::spawn_game();
        let mut world_state = world.world_state();

        // [Move] To generate a shop
        systems.actions.move(Direction::Up);
        
        // Set dungeon to shop
        let mut dungeon: Dungeon = world_state.model_storage.read::<Dungeon>(context.player_id);
        dungeon.monster = Monster::None.into();
        world_state.model_storage.write(context.player_id, dungeon);
        
        // Set player gold to 0
        let mut player: Player = world_state.model_storage.read::<Player>(context.player_id);
        player.gold = 0;
        world_state.model_storage.write(context.player_id, player);

        // [Execute] Try to heal without gold
        // This should panic with "Player: not enough gold"
        systems.actions.heal(1);
    }
    
    /// Tests healing fails if player is not in a shop
    #[test]
    #[should_panic(expected: ('Dungeon: not shop',))]
    fn test_heal_fails_outside_shop() {
        // [Setup] Create test environment
        let (world, systems, context) = setup::spawn_game();
        let world_state = world.world_state();

        // [Move] To generate a dungeon with monster
        systems.actions.move(Direction::Up);

        // [Execute] Try to heal while in combat
        // This should panic with "Dungeon: not shop"
        systems.actions.heal(1);
    }
    
    /// Tests healing with multiple potions
    #[test]
    fn test_heal_multiple_potions() {
        // [Setup] Create test environment
        let (world, systems, context) = setup::spawn_game();
        let mut world_state = world.world_state();

        // [Setup] Give player damage and gold
        let mut player: Player = world_state.model_storage.read::<Player>(context.player_id);
        player.health = 50; // Set to half health
        player.gold = 100;  // Ensure enough gold
        world_state.model_storage.write(context.player_id, player);
        
        // Set dungeon to shop
        let mut dungeon: Dungeon = world_state.model_storage.read::<Dungeon>(context.player_id);
        dungeon.monster = Monster::None.into();
        world_state.model_storage.write(context.player_id, dungeon);

        // Record state before healing
        let player_before: Player = world_state.model_storage.read::<Player>(context.player_id);
        
        // [Heal] with 3 potions
        systems.actions.heal(3);

        // [Assert] Validate healing results
        let player_after: Player = world_state.model_storage.read::<Player>(context.player_id);
        
        // Health should increase by healing amount (3 potions)
        let expected_health = player_before.health + 3 * DEFAULT_POTION_HEAL;
        assert(
            player_after.health == expected_health, 
            'Heal: multi-potion healing incorrect'
        );
        
        // Gold should decrease by potion cost (3 potions)
        let expected_gold = player_before.gold - 3 * DEFAULT_POTION_COST;
        assert(
            player_after.gold == expected_gold, 
            'Heal: multi-potion cost incorrect'
        );
    }
}