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
    fn test_actions_attack() {
        // [Setup]
        let (world, systems, context) = setup::spawn_game();
        let world_state = world.world_state();

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

        // [Assert]
        let player: Player = world_state.model_storage.read::<Player>(context.player_id);
        let dungeon: Dungeon = world_state.model_storage.read::<Dungeon>(context.player_id);
        
        assert(player.health > 0, 'Attack: player health');
        assert(player.gold > 0, 'Attack: player gold');
        assert(dungeon.health == 0, 'Attack: dungeon health');
    }
}