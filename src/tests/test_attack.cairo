// Core imports
use core::debug::PrintTrait;

// Starknet imports
use starknet::testing::{set_contract_address, set_transaction_hash};

// Dojo imports
use dojo::world::{IWorldDispatcher, IWorldDispatcherTrait};

// Internal imports
use rpg::models::player::{Player, PlayerTrait};
use rpg::models::dungeon::{Dungeon, DungeonTrait};
use rpg::types::direction::Direction;
use rpg::systems::actions::IActionsDispatcherTrait;
use rpg::tests::setup::{setup, setup::{Systems, PLAYER}};

#[test]
fn test_actions_attack() {
    // [Setup]
    let (world, systems, context) = setup::spawn_game();

    // [Move]
    systems.actions.move(Direction::Up.into());

    // [Attack] Till death
    loop {
        let dungeon: Dungeon = world.read_model(context.player_id);
        if dungeon.health == 0 {
            break;
        }
        systems.actions.attack();
    };

    // [Assert]
    let player: Player = world.read_model(context.player_id);
    let dungeon: Dungeon = world.read_model(context.player_id);
    assert(player.health > 0, 'Attack: player health');
    assert(player.gold > 0, 'Attack: player gold');
    assert(dungeon.health == 0, 'Attack: dungeon health');
}
