#[cfg(test)]
mod tests {
    use core::debug::PrintTrait;
    use starknet::testing::set_contract_address;
    use dojo::model::{ModelStorage, ModelStorageTest};
    use dojo::world::WorldStorageTrait;

    use crate::models::player::Player;
    use crate::models::dungeon::Dungeon;
    use crate::systems::actions::IActionsDispatcherTrait;
    use crate::tests::setup::tests as setup;

    #[test]
    fn test_actions_setup() {
        // [Setup]
        let (world, _, context) = setup::spawn_game();
        let world_state = world.world_state();

        // [Assert] - Use ModelStorageTest trait to access models
        let player: Player = world_state.model_storage.read::<Player>(context.player_id);
        let dungeon: Dungeon = world_state.model_storage.read::<Dungeon>(context.player_id);
        
        assert(player.id == context.player_id, 'Setup: player id');
        assert(dungeon.health == 0, 'Setup: dungeon health');
    }
}