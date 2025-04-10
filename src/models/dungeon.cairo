#[cfg(test)]
use core::debug::PrintTrait;
use core::traits::Into;
#[cfg(test)]
use core::array::ArrayTrait;

pub use crate::models::index::Dungeon;
pub use crate::types::role::{Role, RoleTrait};
pub use crate::types::monster::{Monster, MonsterTrait};

pub mod errors {
    pub const DUNGEON_NOT_DONE: felt252 = 'Dungeon: not done';
    pub const DUNGEON_ALREADY_DONE: felt252 = 'Dungeon: already done';
    pub const DUNGEON_NOT_SHOP: felt252 = 'Dungeon: not shop';
    pub const DUNGEON_IS_EMPTY: felt252 = 'Dungeon: is empty';
}

#[generate_trait]
pub impl DungeonImpl of DungeonTrait {
    /// Creates a new dungeon with specified monster and role
    /// 
    /// # Arguments
    /// * `id` - The unique identifier for this dungeon (usually player ID)
    /// * `monster` - The type of monster in this dungeon
    /// * `role` - The elemental role/type of the monster
    /// 
    /// # Returns
    /// A new Dungeon instance with properties derived from monster type
    #[inline]
    fn new(id: felt252, monster: Monster, role: Role) -> Dungeon {
        Dungeon {
            id,
            monster: monster.into(),
            role: role.into(),
            damage: monster.damage(),
            health: monster.health(),
            reward: monster.reward(),
        }
    }

    /// Checks if the dungeon is completed (no monster or monster defeated)
    /// 
    /// # Returns
    /// `true` if the dungeon is completed or empty, `false` otherwise
    #[inline]
    fn is_done(self: Dungeon) -> bool {
        self.monster == Monster::None.into() || self.health == 0
    }

    /// Checks if the dungeon is a shop (no monster)
    /// 
    /// # Returns
    /// `true` if the dungeon is a shop, `false` otherwise
    #[inline]
    fn is_shop(self: Dungeon) -> bool {
        self.monster == Monster::None.into()
    }

    /// Applies damage to the monster in this dungeon
    /// 
    /// # Arguments
    /// * `player_role` - The role/element of the attacking player
    /// * `damage` - Base damage amount
    /// 
    /// The actual damage dealt is modified based on elemental advantages/disadvantages
    #[inline]
    fn take_damage(ref self: Dungeon, player_role: Role, damage: u8) {
        // Skip damage calculation for empty dungeons
        if self.monster == Monster::None.into() {
            return;
        }
        
        // Calculate actual damage based on elemental advantages
        let monster_role: Role = self.role.into();
        let received_damage = monster_role.received_damage(player_role, damage);
        
        // Apply damage, capped by current health
        self.health -= core::cmp::min(self.health, received_damage);
    }

    /// Gets the reward for defeating this dungeon's monster
    /// 
    /// # Returns
    /// The gold amount to be rewarded to the player
    #[inline]
    fn get_treasury(self: Dungeon) -> u16 {
        let monster: Monster = self.monster.into();
        monster.reward()
    }
}

#[generate_trait]
pub impl DungeonAssert of AssertTrait {
    /// Asserts that the dungeon is completed or empty
    /// 
    /// Used to ensure a player can't move into a new dungeon without 
    /// completing the current one
    #[inline]
    fn assert_is_done(self: Dungeon) {
        assert(self.is_done(), errors::DUNGEON_NOT_DONE);
    }

    /// Asserts that the dungeon is not completed (has active monster)
    /// 
    /// Used to ensure a player can only attack active monsters
    #[inline]
    fn assert_not_done(self: Dungeon) {
        assert(!self.is_done(), errors::DUNGEON_ALREADY_DONE);
    }

    /// Asserts that the dungeon is a shop (no monster)
    /// 
    /// Used to ensure a player can only heal in shop dungeons
    #[inline]
    fn assert_is_shop(self: Dungeon) {
        assert(self.monster == Monster::None.into(), errors::DUNGEON_NOT_SHOP);
    }
    
    /// Asserts that the dungeon is not empty
    /// 
    /// Used in scenarios where a dungeon must contain a monster
    #[inline]
    fn assert_not_empty(self: Dungeon) {
        assert(self.monster != Monster::None.into(), errors::DUNGEON_IS_EMPTY);
    }
}