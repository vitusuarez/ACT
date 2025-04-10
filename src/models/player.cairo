#[cfg(test)]
use core::debug::PrintTrait;
use core::traits::Into;

use crate::constants::{
    DEFAULT_POTION_HEAL, MAX_PLAYER_HEALTH, DEFAULT_POTION_COST, DEFAULT_PLAYER_DAMAGE,
    DEFAULT_PLAYER_HEALTH, DEFAULT_PLAYER_GOLD
};
use crate::models::index::Player;
use crate::types::role::{Role, RoleTrait};
use crate::types::direction::Direction;
use crate::types::mode::{Mode, ModeTrait};
use crate::types::monster::Monster;
use crate::helpers::seeder::Seeder;

mod errors {
    pub const PLAYER_NOT_EXIST: felt252 = 'Player: does not exist';
    pub const PLAYER_ALREADY_EXIST: felt252 = 'Player: already exist';
    pub const PLAYER_INVALID_NAME: felt252 = 'Player: invalid name';
    pub const PLAYER_INVALID_ROLE: felt252 = 'Player: invalid role';
    pub const PLAYER_INVALID_DIRECTION: felt252 = 'Player: invalid direction';
    pub const PLAYER_NOT_ENOUGH_GOLD: felt252 = 'Player: not enough gold';
    pub const PLAYER_IS_DEAD: felt252 = 'Player: is dead';
    pub const PLAYER_AT_MAX_HEALTH: felt252 = 'Player: already at max health';
}

#[generate_trait]
pub impl PlayerImpl of PlayerTrait {
    /// Creates a new player with default stats
    /// 
    /// # Arguments
    /// * `id` - The unique identifier for the player
    /// * `name` - The player's name (must not be zero)
    /// * `time` - Current timestamp for seed generation
    /// * `mode` - Game difficulty mode
    /// 
    /// # Returns
    /// A new Player instance with initialized stats
    #[inline]
    fn new(id: felt252, name: felt252, time: u64, mode: Mode) -> Player {
        // [Check] Name is valid
        assert(name != 0, errors::PLAYER_INVALID_NAME);
        
        // [Compute] Weekly seed according to the timestamp and the mode
        let seed = Seeder::reseed(Seeder::compute_id(time), mode.into());
        
        // [Return] Player with default stats
        Player {
            id,
            mode: mode.into(),
            role: Role::None.into(),
            damage: DEFAULT_PLAYER_DAMAGE,
            health: DEFAULT_PLAYER_HEALTH,
            gold: DEFAULT_PLAYER_GOLD,
            score: 0,
            seed,
            name
        }
    }

    /// Sets the player's role/class
    /// 
    /// # Arguments
    /// * `role` - The role to assign to the player
    /// 
    /// # Panics
    /// If the role is None
    #[inline]
    fn enrole(ref self: Player, role: Role) {
        // [Check] Role is valid (directly using enum for type safety)
        assert(role != Role::None, errors::PLAYER_INVALID_ROLE);
        
        // [Effect] Change the role
        self.role = role.into();
        
        // [Effect] Update seed based on role for future randomness
        self.seed = Seeder::reseed(self.seed, role.into());
    }

    /// Moves the player in a direction and generates a new encounter
    /// 
    /// # Arguments
    /// * `direction` - The direction to move
    /// 
    /// # Returns
    /// A tuple containing the generated monster and role
    /// 
    /// # Panics
    /// If the direction is None
    #[inline]
    fn move(ref self: Player, direction: Direction) -> (Monster, Role) {
        // [Check] Direction is valid (directly using enum)
        assert(direction != Direction::None, errors::PLAYER_INVALID_DIRECTION);
        
        // [Effect] For the first move, spawn a specific monster and a role
        if self.score == 0 {
            let role: Role = self.role.into();
            return (Monster::Common, role.strength());
        }
        
        // [Effect] Generate monster and role based on player's seed
        let seed: u256 = self.seed.into();
        let mode: Mode = self.mode.into();
        let monster: Monster = mode.monster(seed.low.into());
        let role: Role = mode.role(seed.high.into(), self.role.into());
        
        // [Effect] Update seed for future randomness
        self.seed = Seeder::reseed(self.seed, direction.into());
        
        // [Return] Monster and role for the new encounter
        (monster, role)
    }

    /// Applies damage to the player based on monster's role
    /// 
    /// # Arguments
    /// * `monster_role` - The role/element of the attacking monster
    /// * `damage` - Base damage amount
    #[inline]
    fn take_damage(ref self: Player, monster_role: Role, damage: u8) {
        // Get player's role for damage calculation
        let player_role: Role = self.role.into();
        
        // Calculate actual damage based on elemental advantages/disadvantages
        let received_damage = player_role.received_damage(monster_role, damage);
        
        // Apply damage, capped by current health
        self.health -= core::cmp::min(self.health, received_damage);
    }

    /// Rewards the player after defeating a monster
    /// 
    /// # Arguments
    /// * `gold` - Amount of gold to award
    #[inline]
    fn reward(ref self: Player, gold: u16) {
        // Add gold to player's inventory
        self.gold += gold;
        
        // Increment score (number of monsters defeated)
        self.score += 1;
    }

    /// Heals the player by purchasing potions
    /// 
    /// # Arguments
    /// * `quantity` - Number of potions to purchase
    /// 
    /// # Panics
    /// If the player doesn't have enough gold
    #[inline]
    fn heal(ref self: Player, quantity: u8) {
        // Skip if already at max health
        if self.health == MAX_PLAYER_HEALTH {
            assert(false, errors::PLAYER_AT_MAX_HEALTH);
        }
        
        // [Check] Calculate cost and ensure player can afford it
        let cost: u16 = quantity.into() * DEFAULT_POTION_COST;
        self.assert_is_affordable(cost);
        
        // [Effect] Remove gold
        self.gold -= cost;
        
        // [Effect] Calculate healing amount, ensuring we don't exceed max health
        let healing_amount = core::cmp::min(
            quantity.into() * DEFAULT_POTION_HEAL, 
            MAX_PLAYER_HEALTH - self.health
        );
        
        // [Effect] Restore health
        self.health += healing_amount;
    }
}

#[generate_trait]
pub impl PlayerAssert of AssertTrait {
    /// Asserts that the player exists (has a name)
    #[inline]
    fn assert_exists(self: Player) {
        assert(0 != self.name, errors::PLAYER_NOT_EXIST);
    }

    /// Asserts that the player does not exist (no name)
    #[inline]
    fn assert_not_exists(self: Player) {
        assert(0 == self.name, errors::PLAYER_ALREADY_EXIST);
    }

    /// Asserts that the player is alive (health > 0)
    #[inline]
    fn assert_not_dead(self: Player) {
        assert(self.health != 0, errors::PLAYER_IS_DEAD);
    }

    /// Asserts that the player can afford a purchase
    #[inline]
    fn assert_is_affordable(self: Player, cost: u16) {
        assert(self.gold >= cost, errors::PLAYER_NOT_ENOUGH_GOLD);
    }
}