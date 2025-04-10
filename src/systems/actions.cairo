// Export the interfaces so they can be used in tests
pub use starknet::{ContractAddress, get_caller_address, get_block_timestamp};
pub use dojo::world::{IWorldDispatcher, IWorldDispatcherTrait};

// Define the interface - make it public
#[starknet::interface]
pub trait IActions<TContractState> {
    fn spawn(self: @TContractState, name: felt252, role: crate::types::role::Role);
    fn move(self: @TContractState, direction: crate::types::direction::Direction);
    fn attack(self: @TContractState);
    fn heal(self: @TContractState, quantity: u8);
}

// Contracts
#[dojo::contract]
pub mod actions {
    use starknet::{ContractAddress, get_caller_address, get_block_timestamp};
    
    // Dojo imports
    use dojo::world::{IWorldDispatcher, IWorldDispatcherTrait};
    use dojo::model::ModelStorage;
    use dojo::event::EventStorage;
    
    // Internal imports
    use crate::types::mode::Mode;
    use crate::types::role::Role;
    use crate::types::monster::Monster;
    use crate::types::direction::Direction;
    use crate::models::index::{Player, Dungeon};
    use crate::models::player::{PlayerTrait, AssertTrait as PlayerAssertTrait};
    use crate::models::dungeon::{DungeonTrait, AssertTrait as DungeonAssertTrait};
    
    // Local imports
    use super::IActions;
    
    // Enhanced Dojo events with richer data
    #[derive(Copy, Drop, Serde)]
    #[dojo::event]
    struct Moved {
        #[key]
        player: ContractAddress,
        direction: u8,
        generated_monster: u8,
        generated_role: u8
    }
    
    #[derive(Copy, Drop, Serde)]
    #[dojo::event]
    struct Attacked {
        #[key]
        player: ContractAddress,
        monster_health: u8,
        damage_dealt: u8,
        player_health: u8
    }
    
    #[derive(Copy, Drop, Serde)]
    #[dojo::event]
    struct Healed {
        #[key]
        player: ContractAddress,
        quantity: u8,
        new_health: u8,
        gold_spent: u16
    }
    
    #[derive(Copy, Drop, Serde)]
    #[dojo::event]
    struct Spawned {
        #[key]
        player: ContractAddress,
        name: felt252,
        role: u8,
        mode: u8,
        initial_health: u8,
        initial_damage: u8
    }
    
    // Helper trait for world namespace access with documentation
    #[generate_trait]
    impl InternalImpl of InternalTrait {
        /// Returns the world storage with the RPG namespace
        /// Used by all action methods to access the game state
        fn world_namespace(self: @ContractState) -> dojo::world::WorldStorage {
            self.world(@"rpg")
        }
    }
    
    // Implementations with comprehensive documentation
    #[abi(embed_v0)]
    impl ActionsImpl of IActions<ContractState> {
        /// Spawns a new player in the world with the specified name and role
        /// 
        /// # Arguments
        /// * `name` - The name of the player (cannot be zero)
        /// * `role` - The role (class) of the player (Fire, Water, Earth, Air)
        /// 
        /// # Effects
        /// * Creates a new player with default stats and the specified role
        /// * Creates an initial empty dungeon (shop)
        /// * Emits a Spawned event
        fn spawn(self: @ContractState, name: felt252, role: Role) {
            // Get world storage with the RPG namespace
            let mut world = self.world_namespace();
            
            // Get player address and convert to ID
            let player_address = get_caller_address();
            let player_id: felt252 = player_address.into();
            
            // Get current time for seed generation
            let time: u64 = get_block_timestamp();
            
            // Create player with medium difficulty mode
            let mut player = PlayerTrait::new(player_id, name, time, Mode::Medium);
            
            // Set the player's role (using enum directly for type safety)
            player.enrole(role);
            
            // Create initial dungeon (empty/shop)
            let mut dungeon = DungeonTrait::new(player_id, Monster::None, Role::None);
            
            // Write models to world
            world.write_model(@player);
            world.write_model(@dungeon);
            
            // Emit spawn event with enhanced data
            world.emit_event(
                @Spawned { 
                    player: player_address, 
                    name, 
                    role: role.into(), 
                    mode: Mode::Medium.into(),
                    initial_health: player.health,
                    initial_damage: player.damage
                }
            );
        }

        /// Moves the player in the specified direction, generating a new dungeon encounter
        /// 
        /// # Arguments
        /// * `direction` - The direction to move (Left, Right, Up, Down)
        /// 
        /// # Requirements
        /// * Player must be alive
        /// * Current dungeon must be completed or empty
        /// 
        /// # Effects
        /// * Generates a new dungeon with monster and role based on player's seed
        /// * Updates player's seed for future randomness
        /// * Emits a Moved event
        fn move(self: @ContractState, direction: Direction) {
            // Get world storage
            let mut world = self.world_namespace();
            
            // Get player address and convert to ID
            let player_address = get_caller_address();
            let player_id: felt252 = player_address.into();
            
            // Read player and dungeon state
            let mut player: Player = world.read_model(player_id);
            let dungeon: Dungeon = world.read_model(player_id);
            
            // Ensure player is alive
            player.assert_not_dead();
            
            // Ensure current dungeon is completed or empty
            dungeon.assert_is_done();
            
            // Move player and generate new encounter (using enum directly)
            let (monster, role) = player.move(direction);
            let mut new_dungeon: Dungeon = DungeonTrait::new(player_id, monster, role);
            
            // Write updated models to world
            world.write_model(@player);
            world.write_model(@new_dungeon);
            
            // Emit movement event with enhanced data about the new dungeon
            world.emit_event(
                @Moved { 
                    player: player_address, 
                    direction: direction.into(),
                    generated_monster: monster.into(),
                    generated_role: role.into()
                }
            );
        }

        /// Attacks the monster in the current dungeon
        /// 
        /// # Requirements
        /// * Player must be alive
        /// * Current dungeon must have an active monster
        /// 
        /// # Effects
        /// * Applies player's damage to the monster, considering role advantages
        /// * If monster survives, it counterattacks the player
        /// * If monster is defeated, awards gold and score to player
        /// * Emits an Attacked event
        fn attack(self: @ContractState) {
            // Get world storage
            let mut world = self.world_namespace();
            
            // Get player address and convert to ID
            let player_address = get_caller_address();
            let player_id: felt252 = player_address.into();
            
            // Read player and dungeon state
            let mut player: Player = world.read_model(player_id);
            let mut dungeon: Dungeon = world.read_model(player_id);
            
            // Ensure player is alive
            player.assert_not_dead();
            
            // Ensure dungeon has an active monster
            dungeon.assert_not_done();
            
            // Calculate player's damage
            let player_role: Role = player.role.into();
            let damage_to_deal = player.damage;
            
            // Apply damage to monster, considering role advantages
            dungeon.take_damage(player_role, damage_to_deal);
            
            // Check if monster is defeated
            if dungeon.is_done() {
                // Award player with gold and score
                player.reward(dungeon.get_treasury());
            } else {
                // Monster counterattacks if still alive
                let monster_role: Role = dungeon.role.into();
                player.take_damage(monster_role, dungeon.damage);
            }
            
            // Write updated models to world
            world.write_model(@player);
            world.write_model(@dungeon);
            
            // Emit attack event with enhanced data
            world.emit_event(
                @Attacked { 
                    player: player_address, 
                    monster_health: dungeon.health,
                    damage_dealt: damage_to_deal,
                    player_health: player.health
                }
            );
        }

        /// Heals the player by purchasing potions
        /// 
        /// # Arguments
        /// * `quantity` - The number of potions to purchase
        /// 
        /// # Requirements
        /// * Player must be alive
        /// * Player must be in a shop (dungeon with no monster)
        /// * Player must have enough gold to purchase the potions
        /// 
        /// # Effects
        /// * Deducts gold from player based on potion quantity and cost
        /// * Increases player's health
        /// * Emits a Healed event
        fn heal(self: @ContractState, quantity: u8) {
            // Get world storage
            let mut world = self.world_namespace();
            
            // Get player address and convert to ID
            let player_address = get_caller_address();
            let player_id: felt252 = player_address.into();
            
            // Read player and dungeon state
            let mut player: Player = world.read_model(player_id);
            let dungeon: Dungeon = world.read_model(player_id);
            
            // Ensure player is alive
            player.assert_not_dead();
            
            // Ensure player is in a shop (dungeon with no monster)
            dungeon.assert_is_shop();
            
            // Calculate cost before healing for the event
            let cost: u16 = quantity.into() * crate::constants::DEFAULT_POTION_COST;
            
            // Store original health for comparison
            let _old_health = player.health;  // Prefix with _ to avoid unused var warning
            
            // Heal player (this already handles gold cost)
            player.heal(quantity);
            
            // Write updated player model to world
            world.write_model(@player);
            
            // Emit healing event with enhanced data
            world.emit_event(
                @Healed { 
                    player: player_address, 
                    quantity,
                    new_health: player.health,
                    gold_spent: cost
                }
            );
        }
    }
}