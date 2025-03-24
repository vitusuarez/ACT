// Starknet imports
use starknet::ContractAddress;
use starknet::info::{get_caller_address, get_block_timestamp};

// Dojo imports
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
    
    // Internal imports
    use rpg::types::mode::Mode;
    use rpg::types::role::Role;
    use rpg::types::monster::Monster;
    use rpg::types::direction::Direction;
    use rpg::models::player::{Player, PlayerTrait, PlayerAssert};
    use rpg::models::dungeon::{Dungeon, DungeonTrait, DungeonAssert};
    
    // Local imports
    use super::IActions;
    
    // Events
    #[derive(Drop, starknet::Event)]
    struct PlayerSpawned {
        #[key]
        player: ContractAddress,
        name: felt252,
        role: u8
    }
    
    #[derive(Drop, starknet::Event)]
    struct PlayerMoved {
        #[key]
        player: ContractAddress,
        direction: u8
    }
    
    #[derive(Drop, starknet::Event)]
    struct PlayerAttacked {
        #[key]
        player: ContractAddress,
        monster_health: u8
    }
    
    #[derive(Drop, starknet::Event)]
    struct PlayerHealed {
        #[key]
        player: ContractAddress,
        quantity: u8
    }
    
    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        PlayerSpawned: PlayerSpawned,
        PlayerMoved: PlayerMoved,
        PlayerAttacked: PlayerAttacked,
        PlayerHealed: PlayerHealed
    }
    
    // Implementations
    #[abi(embed_v0)]
    impl ActionsImpl of IActions<ContractState> {
        fn spawn(self: @ContractState, name: felt252, role: u8) {
            let world = self.world(@"rpg");
            let player_address = get_caller_address();
            let player_id: felt252 = player_address.into();
            let time: u64 = get_block_timestamp();
            
            // Create player
            let mut player = PlayerTrait::new(player_id, name, time, Mode::Medium);
            player.enrole(role.into());
            
            // Create initial dungeon (empty)
            let dungeon = DungeonTrait::new(player_id, Monster::None, Role::None);
            
            // Write to world
            world.write_model(@player);
            world.write_model(@dungeon);
            
            // Emit event
            world.emit_event(
                PlayerSpawned { player: player_address, name: name, role: role }
            );
        }

        fn move(self: @ContractState, direction: u8) {
            let world = self.world(@"rpg");
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
            let new_dungeon: Dungeon = DungeonTrait::new(player_id, monster, role);
            
            // Update state
            world.write_model(@player);
            world.write_model(@new_dungeon);
            
            // Emit event
            world.emit_event(
                PlayerMoved { player: player_address, direction: direction }
            );
        }

        fn attack(self: @ContractState) {
            let world = self.world(@"rpg");
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
            
            // Emit event
            world.emit_event(
                PlayerAttacked { player: player_address, monster_health: dungeon.health }
            );
        }

        fn heal(self: @ContractState, quantity: u8) {
            let world = self.world(@"rpg");
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
            
            // Emit event
            world.emit_event(
                PlayerHealed { player: player_address, quantity: quantity }
            );
        }
    }
}
