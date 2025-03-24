mod constants;
mod helpers {
    mod seeder;
}

mod types {
    mod direction;
    mod mode;
    mod monster;
    mod role;
}

mod models {
    mod index;
    mod dungeon;
    mod player;
}

mod systems {
    mod actions;
}

mod elements {
    mod modes {
        mod interface;
        mod easy;
        mod medium;
        mod hard;
    }
    mod monsters {
        mod interface;
        mod common;
        mod elite;
        mod boss;
    }
    mod roles {
        mod interface;
        mod fire;
        mod water;
        mod earth;
        mod air;
    }
}

#[cfg(test)]
mod tests {
    mod setup;
    mod test_setup;
    mod test_move;
    mod test_attack;
    mod test_heal;
}
