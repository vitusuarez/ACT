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
fn test_actions_heal() {
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

    // [Move]
    systems.actions.move(Direction::Up.into());
    let mut dungeon: Dungeon = world.read_model(context.player_id);
    dungeon.monster = 0;
    world.write_model(@dungeon);

    // [Heal]
    let player: Player = world.read_model(context.player_id);
    let player_health = player.health;
    let player_gold = player.gold;
    systems.actions.heal(1);

    // [Assert]
    let player: Player = world.read_model(context.player_id);
    assert(player.health > player_health, 'Attack: player health');
    assert(player.gold < player_gold, 'Attack: player gold');
}
