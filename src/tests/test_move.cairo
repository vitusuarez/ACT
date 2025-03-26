#[cfg(test)]
mod tests {
    use core::debug::PrintTrait;
    use starknet::testing::set_contract_address;
    use dojo::model::{ModelStorage, ModelStorageTest};
    use dojo::world::WorldStorageTrait;

    use crate::models::dungeon::Dungeon;
    use crate::types::direction::Direction;
    use crate::systems::actions::IActionsDispatcherTrait;
    use crate::tests::setup::tests as setup;

    #[test]
    fn test_actions_move() {
        // [Setup]
        let (world, systems, context) = setup::spawn_game();
        let world_state = world.world_state();

        // [Move]
        systems.actions.move(Direction::Up.into());

        // [Assert]
        let dungeon: Dungeon = world_state.model_storage.read::<Dungeon>(context.player_id);
        assert(dungeon.health > 0, 'Move: dungeon health');
    }
}