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
        pub mod interface;
        pub mod easy;
        pub mod medium;
        pub mod hard;
    }
    pub mod monsters {
        pub mod interface;
        pub mod common;
        pub mod elite;
        pub mod boss;
    }
    pub mod roles {
        pub mod interface;
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

// Re-export key types for better visibility
pub use types::direction::Direction;
pub use types::mode::Mode;
pub use types::monster::Monster;
pub use types::role::Role;