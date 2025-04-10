// Starknet imports
use starknet::{ContractAddress, get_caller_address};

// Dojo imports
use dojo::world::{IWorldDispatcher, IWorldDispatcherTrait};
use dojo::model::{ModelStorage};
use dojo::event::EventStorage;

// Internal imports
use crate::models::index::{Player, Dungeon};
use crate::models::player::{PlayerTrait, AssertTrait as PlayerAssertTrait};
use crate::models::dungeon::{DungeonTrait, AssertTrait as DungeonAssertTrait};
use crate::types::role::Role;
use crate::types::direction::Direction;
use crate::types::monster::Monster;
use crate::types::mode::Mode;

/// PlayableComponent provides reusable game functionality that can be
/// integrated into various systems
#[dojo::contract]
pub mod PlayableComponent {
    use super::*;

    /// Event emitted when a player is spawned
    #[derive(Copy, Drop, Serde)]
    #[dojo::event]
    pub struct PlayerSpawned {
        #[key]
        pub player: ContractAddress,
        pub name: felt252,
        pub role: u8,
        pub mode: u8,
        pub initial_health: u8,
        pub initial_damage: u8
    }

    /// Event emitted when a player moves
    #[derive(Copy, Drop, Serde)]
    #[dojo::event]
    pub struct PlayerMoved {
        #[key]
        pub player: ContractAddress,
        pub direction: u8,
        pub generated_monster: u8,
        pub generated_role: u8
    }

    /// Event emitted when a player attacks
    #[derive(Copy, Drop, Serde)]
    #[dojo::event]
    pub struct PlayerAttacked {
        #[key]
        pub player: ContractAddress,
        pub damage_dealt: u8,
        pub monster_health: u8,
        pub player_health: u8
    }

    /// Event emitted when a player heals
    #[derive(Copy, Drop, Serde)]
    #[dojo::event]
    pub struct PlayerHealed {
        #[key]
        pub player: ContractAddress,
        pub quantity: u8,
        pub new_health: u8,
        pub gold_spent: u16
    }

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
        /// Spawns a new player in the world
        /// 
        /// # Arguments
        /// * `world` - The world dispatcher
        /// * `name` - The player's name
        /// * `role` - The player's role/class
        /// * `mode` - The game difficulty mode
        fn spawn(
            ref self: ContractState, world: IWorldDispatcher, name: felt252, role: Role, mode: Mode
        ) {
            // Get world storage
            let mut world_storage = world(@"rpg");
            
            // Get caller address
            let caller = get_caller_address();
            
            // Get current time 
            let current_time: u64 = starknet::get_block_timestamp();
            
            // Create new player
            let mut player = PlayerTrait::new(caller.into(), name, current_time, mode);
            
            // Set role if provided
            if role != Role::None {
                player.enrole(role);
            }
            
            // Create initial dungeon (empty/shop)
            let dungeon = DungeonTrait::new(caller.into(), Monster::None, Role::None);
            
            // Write models to world
            world_storage.write_model(@player);
            world_storage.write_model(@dungeon);
            
            // Emit event
            world_storage.emit_event(@PlayerSpawned {
                player: caller,
                name,
                role: role.into(),
                mode: mode.into(),
                initial_health: player.health,
                initial_damage: player.damage
            });
        }

        /// Moves the player in a specific direction
        /// 
        /// # Arguments
        /// * `world` - The world dispatcher
        /// * `direction` - The direction to move
        fn move(
            ref self: ContractState, world: IWorldDispatcher, direction: Direction
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
            
            // Read current dungeon
            let dungeon: Dungeon = world_storage.read_model(caller);
            
            // Ensure current dungeon is completed
            dungeon.assert_is_done();
            
            // Move player and get monster/role
            let (monster, role) = player.move(direction);
            
            // Create new dungeon
            let dungeon = DungeonTrait::new(caller.into(), monster, role);
            
            // Write models back to world
            world_storage.write_model(@player);
            world_storage.write_model(@dungeon);
            
            // Emit event
            world_storage.emit_event(@PlayerMoved {
                player: caller,
                direction: direction.into(),
                generated_monster: monster.into(),
                generated_role: role.into()
            });
        }

        /// Attacks the monster in the current dungeon
        /// 
        /// # Arguments
        /// * `world` - The world dispatcher
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
            let damage_to_deal = player.damage;
            dungeon.take_damage(player_role, damage_to_deal);
            
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
            world_storage.emit_event(@PlayerAttacked {
                player: caller,
                damage_dealt: damage_to_deal,
                monster_health: dungeon.health,
                player_health: player.health
            });
        }

        /// Heals the player by purchasing potions
        /// 
        /// # Arguments
        /// * `world` - The world dispatcher
        /// * `quantity` - The number of potions to purchase
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
            
            // Calculate cost before healing for the event
            let cost: u16 = quantity.into() * crate::constants::DEFAULT_POTION_COST;
            
            // Heal player
            player.heal(quantity);
            
            // Write model back to world
            world_storage.write_model(@player);
            
            // Emit event
            world_storage.emit_event(@PlayerHealed {
                player: caller,
                quantity,
                new_health: player.health,
                gold_spent: cost
            });
        }
    }
}