use starknet::ContractAddress;
use starknet::info::{get_caller_address, get_block_timestamp};
use dojo::world::{IWorldDispatcher, IWorldDispatcherTrait};

// Interfaces
#[starknet::interface]
trait IActions<TContractState> {
    fn spawn(self: @TContractState, name: felt252, role: u8);
    fn move(self: @TContractState, direction: u8);
    fn attack(self: @TContractState);
    fn heal(self: @TContractState, quantity: u8);
}

// Contracts
#[dojo::contract]
mod actions {
    use starknet::ContractAddress;
    use starknet::info::{get_caller_address, get_block_timestamp};
    
    // Dojo imports
    use dojo::world::{IWorldDispatcher, IWorldDispatcherTrait};
    use dojo::model::ModelStorage;
    use dojo::event::EventStorage;
    
    // Internal imports
    use crate::types::mode::Mode;
    use crate::types::role::Role;
    use crate::types::monster::Monster;
    use crate::types::direction::Direction;
    use crate::models::player::{Player, PlayerTrait, PlayerAssert};
    use crate::models::dungeon::{Dungeon, DungeonTrait, DungeonAssert};
    
    // Local imports
    use super::IActions;
    
    // Dojo events
    #[derive(Copy, Drop, Serde)]
    #[dojo::event]
    struct Moved {
        #[key]
        player: ContractAddress,
        direction: u8
    }
    
    #[derive(Copy, Drop, Serde)]
    #[dojo::event]
    struct Attacked {
        #[key]
        player: ContractAddress,
        monster_health: u8
    }
    
    #[derive(Copy, Drop, Serde)]
    #[dojo::event]
    struct Healed {
        #[key]
        player: ContractAddress,
        quantity: u8
    }
    
    #[derive(Copy, Drop, Serde)]
    #[dojo::event]
    struct Spawned {
        #[key]
        player: ContractAddress,
        name: felt252,
        role: u8
    }
    
    // Helper trait for world namespace access
    #[generate_trait]
    impl InternalImpl of InternalTrait {
        fn world_namespace(self: @ContractState) -> dojo::world::WorldStorage {
            self.world(@"rpg")
        }
    }
    
    // Implementations
    #[abi(embed_v0)]
    impl ActionsImpl of IActions<ContractState> {
        fn spawn(self: @ContractState, name: felt252, role: u8) {
            let mut world = self.world_namespace();
            let player_address = get_caller_address();
            let player_id: felt252 = player_address.into();
            let time: u64 = get_block_timestamp();
            
            // Create player
            let mut player = PlayerTrait::new(player_id, name, time, Mode::Medium);
            player.enrole(role.into());
            
            // Create initial dungeon (empty)
            let mut dungeon = DungeonTrait::new(player_id, Monster::None, Role::None);
            
            // Write to world
            world.write_model(@player);
            world.write_model(@dungeon);
            
            // Emit Dojo event
            world.emit_event(
                @Spawned { player: player_address, name: name, role: role }
            );
        }

        fn move(self: @ContractState, direction: u8) {
            let mut world = self.world_namespace();
            let player_address = get_caller_address();
            let player_id: felt252 = player_address.into();
            
            // Read player and dungeon
            let mut player: Player = world.read_model(player_id);
            let dungeon: Dungeon = world.read_model(player_id);
            
            // Check player is not dead
            player.assert_not_dead();
            
            // Check current dungeon is done
            dungeon.assert_is_done();
            
            // Move player
            let (monster, role) = player.move(direction.into());
            let mut new_dungeon: Dungeon = DungeonTrait::new(player_id, monster, role);
            
            // Update state
            world.write_model(@player);
            world.write_model(@new_dungeon);
            
            // Emit Dojo event
            world.emit_event(
                @Moved { player: player_address, direction: direction }
            );
        }

        fn attack(self: @ContractState) {
            let mut world = self.world_namespace();
            let player_address = get_caller_address();
            let player_id: felt252 = player_address.into();
            
            // Read player and dungeon
            let mut player: Player = world.read_model(player_id);
            let mut dungeon: Dungeon = world.read_model(player_id);
            
            // Check player is not dead
            player.assert_not_dead();
            
            // Check current dungeon is not done
            dungeon.assert_not_done();
            
            // Attack
            dungeon.take_damage(player.role.into(), player.damage);
            
            // Defend (if dungeon is not dead)
            if dungeon.is_done() {
                player.reward(dungeon.get_treasury());
            } else {
                player.take_damage(dungeon.role.into(), dungeon.damage);
            }
            
            // Update state
            world.write_model(@player);
            world.write_model(@dungeon);
            
            // Emit Dojo event
            world.emit_event(
                @Attacked { player: player_address, monster_health: dungeon.health }
            );
        }

        fn heal(self: @ContractState, quantity: u8) {
            let mut world = self.world_namespace();
            let player_address = get_caller_address();
            let player_id: felt252 = player_address.into();
            
            // Read player and dungeon
            let mut player: Player = world.read_model(player_id);
            let dungeon: Dungeon = world.read_model(player_id);
            
            // Check player is not dead
            player.assert_not_dead();
            
            // Check current dungeon is a shop
            dungeon.assert_is_shop();
            
            // Heal
            player.heal(quantity);
            
            // Update state
            world.write_model(@player);
            
            // Emit Dojo event
            world.emit_event(
                @Healed { player: player_address, quantity: quantity }
            );
        }
    }
}