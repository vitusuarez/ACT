#[cfg(test)]
mod tests {
    use core::debug::PrintTrait;
    use starknet::testing::set_contract_address;
    use dojo::model::{ModelStorage, ModelStorageTest};
    use dojo::world::WorldStorageTrait;

    use crate::models::player::Player;
    use crate::models::dungeon::Dungeon;
    use crate::types::direction::Direction;
    use crate::systems::actions::IActionsDispatcherTrait;
    use crate::tests::setup::tests as setup;

    #[test]
    fn test_actions_heal() {
        // [Setup]
        let (world, systems, context) = setup::spawn_game();
        let mut world_state = world.world_state();

        // [Move]
        systems.actions.move(Direction::Up.into());

        // [Attack] Till death
        loop {
            let dungeon: Dungeon = world_state.model_storage.read::<Dungeon>(context.player_id);
            if dungeon.health == 0 {
                break;
            }
            systems.actions.attack();
        };

        // [Move]
        systems.actions.move(Direction::Up.into());
        
        // Modify the dungeon to be a shop (monster = 0)
        let mut dungeon: Dungeon = world_state.model_storage.read::<Dungeon>(context.player_id);
        dungeon.monster = 0;
        world_state.model_storage.write(context.player_id, dungeon);

        // [Heal]
        let player: Player = world_state.model_storage.read::<Player>(context.player_id);
        let player_health = player.health;
        let player_gold = player.gold;
        systems.actions.heal(1);

        // [Assert]
        let player: Player = world_state.model_storage.read::<Player>(context.player_id);
        assert(player.health > player_health, 'Heal: player health');
        assert(player.gold < player_gold, 'Heal: player gold');
    }
}