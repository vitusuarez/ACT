// Starknet imports
use starknet::{ContractAddress, get_caller_address};

// Dojo imports
use dojo::world::{IWorldDispatcher, IWorldDispatcherTrait};
use dojo::model::{ModelStorage};
use dojo::event::EventStorage;

// Internal imports
use rpg::models::index::{Player, Dungeon};
use rpg::models::player::{PlayerTrait, AssertTrait as PlayerAssertTrait};
use rpg::models::dungeon::{DungeonTrait, AssertTrait as DungeonAssertTrait};
use rpg::types::role::Role;
use rpg::types::direction::Direction;
use rpg::types::monster::Monster;

#[derive(Copy, Drop, Serde)]
#[dojo::event]
pub struct PlayerSpawned {
    #[key]
    pub player: ContractAddress,
    pub name: felt252,
    pub role: u8,
    pub mode: u8,
}

#[derive(Copy, Drop, Serde)]
#[dojo::event]
pub struct PlayerMoved {
    #[key]
    pub player: ContractAddress,
    pub direction: u8,
}

#[derive(Copy, Drop, Serde)]
#[dojo::event]
pub struct PlayerAttacked {
    #[key]
    pub player: ContractAddress,
    pub damage_dealt: u8, // Added a non-key field to satisfy Dojo's event requirements
}

#[derive(Copy, Drop, Serde)]
#[dojo::event]
pub struct PlayerHealed {
    #[key]
    pub player: ContractAddress,
    pub quantity: u8,
}

#[dojo::contract]
pub mod PlayableComponent {
    use super::*;

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        PlayerSpawned: PlayerSpawned,
        PlayerMoved: PlayerMoved,
        PlayerAttacked: PlayerAttacked,
        PlayerHealed: PlayerHealed,
    }

    #[generate_trait]
    pub impl InternalImpl of InternalTrait {
        fn spawn(
            ref self: ContractState, world: IWorldDispatcher, name: felt252, role: u8, mode: u8
        ) {
            // Get world storage
            let mut world_storage = world(@"rpg");
            
            // Get caller address
            let caller = get_caller_address();
            
            // Get current time 
            let current_time: u64 = starknet::get_block_timestamp();
            
            // Create new player
            let mut player = PlayerTrait::new(caller.into(), name, current_time, mode.into());
            
            // Set role if provided
            if role != Role::None.into() {
                player.enrole(role.into());
            }
            
            // Create initial dungeon (empty/shop)
            let dungeon = DungeonTrait::new(caller.into(), Monster::None.into(), Role::None.into());
            
            // Write models to world
            world_storage.write_model(@player);
            world_storage.write_model(@dungeon);
            
            // Emit event
            world_storage.emit_event(PlayerSpawned {
                player: caller,
                name: name,
                role: role,
                mode: mode,
            });
        }

        fn move(
            ref self: ContractState, world: IWorldDispatcher, direction: u8
        ) {
            // Get world storage
            let mut world_storage = world(@"rpg");
            
            // Get caller address
            let caller = get_caller_address();
            
            // Read player data
            let mut player: Player = world_storage.read_model(caller);
            
            // Validate player exists and is alive
            player.assert_exists();
            player.assert_not_dead();
            
            // Move player and get monster/role
            let (monster, role) = player.move(direction.into());
            
            // Create new dungeon
            let dungeon = DungeonTrait::new(caller.into(), monster.into(), role.into());
            
            // Write models back to world
            world_storage.write_model(@player);
            world_storage.write_model(@dungeon);
            
            // Emit event
            world_storage.emit_event(PlayerMoved {
                player: caller,
                direction: direction,
            });
        }

        fn attack(
            ref self: ContractState, world: IWorldDispatcher
        ) {
            // Get world storage
            let mut world_storage = world(@"rpg");
            
            // Get caller address
            let caller = get_caller_address();
            
            // Read player and dungeon data
            let mut player: Player = world_storage.read_model(caller);
            let mut dungeon: Dungeon = world_storage.read_model(caller);
            
            // Validate player exists and is alive
            player.assert_exists();
            player.assert_not_dead();
            
            // Validate dungeon is not done
            dungeon.assert_not_done();
            
            // Apply damage to dungeon
            let player_role: Role = player.role.into();
            dungeon.take_damage(player_role, player.damage);
            
            // Store damage for event
            let damage_dealt = player.damage;
            
            // If dungeon is done after attack, give reward
            if dungeon.is_done() {
                player.reward(dungeon.reward);
            } else {
                // Otherwise player takes damage
                let monster_role: Role = dungeon.role.into();
                player.take_damage(monster_role, dungeon.damage);
            }
            
            // Write models back to world
            world_storage.write_model(@player);
            world_storage.write_model(@dungeon);
            
            // Emit event
            world_storage.emit_event(PlayerAttacked {
                player: caller,
                damage_dealt: damage_dealt,
            });
        }

        fn heal(
            ref self: ContractState, world: IWorldDispatcher, quantity: u8
        ) {
            // Get world storage
            let mut world_storage = world(@"rpg");
            
            // Get caller address
            let caller = get_caller_address();
            
            // Read player data
            let mut player: Player = world_storage.read_model(caller);
            
            // Validate player exists and is alive
            player.assert_exists();
            player.assert_not_dead();
            
            // Validate dungeon is a shop
            let dungeon: Dungeon = world_storage.read_model(caller);
            dungeon.assert_is_shop();
            
            // Heal player
            player.heal(quantity);
            
            // Write model back to world
            world_storage.write_model(@player);
            
            // Emit event
            world_storage.emit_event(PlayerHealed {
                player: caller,
                quantity: quantity,
            });
        }
    }
}
