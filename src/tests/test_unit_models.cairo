#[cfg(test)]mod tests {    // Local imports    use super::{        Player, PlayerTrait, AssertTrait, Role, Mode, ModeTrait, Direction, Monster, MonsterTrait,        DEFAULT_PLAYER_DAMAGE, DEFAULT_PLAYER_HEALTH, DEFAULT_PLAYER_GOLD, DEFAULT_POTION_COST,        DEFAULT_POTION_HEAL, MAX_PLAYER_HEALTH    };    // Constants    const ID: felt252 = 'ID';    const PLAYER_NAME: felt252 = 'Alice';    const TIME: u64 = 0;    const MODE: Mode = Mode::Easy;    /// Tests player creation    #[test]    fn test_player_new() {        let player = PlayerTrait::new(ID, PLAYER_NAME, TIME, MODE);        assert_eq!(player.id, ID);        assert_eq!(player.name, PLAYER_NAME);        assert_eq!(player.mode, MODE.into());        assert_eq!(player.role, Role::None.into());        assert_eq!(player.damage, DEFAULT_PLAYER_DAMAGE);        assert_eq!(player.health, DEFAULT_PLAYER_HEALTH);        assert_eq!(player.gold, DEFAULT_PLAYER_GOLD);        assert_eq!(player.score, 0);    }    /// Tests player role assignment    #[test]    fn test_player_enrole() {        let mut player = PlayerTrait::new(ID, PLAYER_NAME, TIME, MODE);                // Assign Fire role        player.enrole(Role::Fire);        assert_eq!(player.role, Role::Fire.into());                // Change to Water role        player.enrole(Role::Water);        assert_eq!(player.role, Role::Water.into());    }        /// Tests player role validation    #[test]    #[should_panic(expected: ('Player: invalid role',))]    fn test_player_enrole_invalid() {        let mut player = PlayerTrait::new(ID, PLAYER_NAME, TIME, MODE);        player.enrole(Role::None);  // Should panic - None is not valid    }    /// Tests player movement and encounter generation    #[test]    fn test_player_move() {        let mut player = PlayerTrait::new(ID, PLAYER_NAME, TIME, MODE);        let seed = player.seed;                // First move should generate a Common monster        let (monster, role) = player.move(Direction::Up);        assert(monster == Monster::Common, 'First move should give Common');                // Seed should change after move        assert(seed != player.seed, 'Seed should change after move');                // Subsequent moves should generate monsters based on mode/seed        player.enrole(Role::Fire);        let (monster2, role2) = player.move(Direction::Left);        assert(player.score == 1, 'Score should increase after move');    }    /// Tests damage calculation for player    #[test]    fn test_player_take_damage() {        let mut player = PlayerTrait::new(ID, PLAYER_NAME, TIME, MODE);        player.enrole(Role::Fire); // Fire is weak against Water                // Regular damage        let initial_health = player.health;        player.take_damage(Role::Earth, 10);        assert(player.health == initial_health - 10, 'Regular damage incorrect');                // Weakness damage (should be doubled)        let health_before_weakness = player.health;        player.take_damage(Role::Water, 10);        assert(player.health == health_before_weakness - 20, 'Weakness damage incorrect');                // Strength damage (should be halved)        let health_before_strength = player.health;        player.take_damage(Role::Air, 10);        assert(player.health == health_before_strength - 5, 'Strength damage incorrect');    }    /// Tests player reward mechanism    #[test]    fn test_player_reward() {        let mut player = PlayerTrait::new(ID, PLAYER_NAME, TIME, MODE);                // Add gold and score        player.reward(10);        assert_eq!(player.gold, DEFAULT_PLAYER_GOLD + 10, 'Gold not added correctly');        assert_eq!(player.score, 1, 'Score not incremented');                // Add more        player.reward(20);        assert_eq!(player.gold, DEFAULT_PLAYER_GOLD + 30, 'Cumulative gold incorrect');        assert_eq!(player.score, 2, 'Cumulative score incorrect');    }    /// Tests basic healing    #[test]    fn test_player_heal() {        let mut player = PlayerTrait::new(ID, PLAYER_NAME, TIME, MODE);                // Reduce health first        player.health = 50;                // Add gold for healing        player.gold = DEFAULT_POTION_COST;                // Heal        player.heal(1);        assert_eq!(player.gold, 0, 'Gold not deducted correctly');        assert_eq!(player.health, 50 + DEFAULT_POTION_HEAL, 'Health not increased correctly');    }        /// Tests maximum health cap for healing    #[test]    fn test_player_heal_max_cap() {        let mut player = PlayerTrait::new(ID, PLAYER_NAME, TIME, MODE);                // Set health close to max        player.health = MAX_PLAYER_HEALTH - 5;                // Add plenty of gold        player.gold = DEFAULT_POTION_COST * 10;                // Try to heal more than needed        player.heal(1);  // Would normally add DEFAULT_POTION_HEAL (20)                // Should be capped at MAX_PLAYER_HEALTH        assert_eq!(player.health, MAX_PLAYER_HEALTH, 'Health exceeds maximum');    }        /// Tests healing cost calculation    #[test]    fn test_player_heal_costs() {        let mut player = PlayerTrait::new(ID, PLAYER_NAME, TIME, MODE);        player.health = 50;                // Add exact gold for 3 potions        let potion_count = 3;        player.gold = DEFAULT_POTION_COST * potion_count;                // Heal        player.heal(potion_count);        assert_eq!(player.gold, 0, 'Gold calculation incorrect');        assert_eq!(            player.health,             50 + DEFAULT_POTION_HEAL * potion_count,             'Multi-potion healing incorrect'        );    }        /// Tests healing fails without enough gold    #[test]    #[should_panic(expected: ('Player: not enough gold',))]    fn test_player_heal_insufficient_gold() {        let mut player = PlayerTrait::new(ID, PLAYER_NAME, TIME, MODE);        player.health = 50;        player.gold = DEFAULT_POTION_COST - 1;  // Not quite enough                player.heal(1);  // Should panic    }        /// Tests heal failure at max health    #[test]    #[should_panic(expected: ('Player: already at max health',))]    fn test_player_heal_at_max_health() {        let mut player = PlayerTrait::new(ID, PLAYER_NAME, TIME, MODE);        player.health = MAX_PLAYER_HEALTH;        player.gold = DEFAULT_POTION_COST * 10;                player.heal(1);  // Should panic - already at max health    }}