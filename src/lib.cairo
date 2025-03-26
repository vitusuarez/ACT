// Make all modules public
pub mod constants;
pub mod helpers {
    pub mod seeder;
}

pub mod types {
    pub mod direction;
    pub mod mode;
    pub mod monster;
    pub mod role;
}

pub mod models {
    pub mod index;
    pub mod dungeon;
    pub mod player;
}

pub mod systems {
    pub mod actions;
}

pub mod elements {
    pub mod modes {
        pub mod easy;
        pub mod medium;
        pub mod hard;
    }
    pub mod monsters {
        pub mod common;
        pub mod elite;
        pub mod boss;
    }
    pub mod roles {
        pub mod fire;
        pub mod water;
        pub mod earth;
        pub mod air;
    }
}

#[cfg(test)]
pub mod tests {
    pub mod setup;
    pub mod test_setup;
    pub mod test_move;
    pub mod test_attack;
    pub mod test_heal;
}

// Re-export key types and traits for better visibility
pub use types::direction::Direction;
pub use types::mode::{Mode, ModeTrait};
pub use types::monster::{Monster, MonsterTrait};
pub use types::role::{Role, RoleTrait};

// Re-export implementations
pub use helpers::seeder::Seeder;
pub use models::player::{PlayerTrait, AssertTrait as PlayerAssertTrait};
pub use models::dungeon::{DungeonTrait, AssertTrait as DungeonAssertTrait};