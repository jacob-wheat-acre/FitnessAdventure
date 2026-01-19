//
//  Enemies_Cave.swift
//  FittnessRPG
//

import Foundation

struct EnemiesCave {
    static let all: [RPGEnemy] = [
        EnemyBuild.e(
            "cave_bat_colony",
            "Bat Cloud",
            hp: 6,
            armor: [EnemyBuild.a(.stability, 2)],
            narrative: EnemyBuild.n(
                "A large group of bats engulf you. You swing wildly hoping to disperse them.",
                "It seems something scared these bats out from their typical roosts. What could have invaded the cave?",
                "At first, these bats seemed against you. You realized something else got them into a frenzied state."
            )
        ),

        EnemyBuild.e(
            "cave_id_rat_with_a_sword",
            "Rat with a Sword",
            hp: 7,
            armor: [EnemyBuild.a(.stability, 3)],
            narrative: EnemyBuild.n(
                "Oh my goodness, is this the rat from earlier? How did it learn to pick up a sword?",
                "You were able to scrape by. This rat keeps getting stronger!",
                "This rat came at you earlier, but it trained and learned to fight with a sword. Amazing."
            )
        ),
        
        EnemyBuild.e(
            "cave_id_invading_raccoon",
            "Invading Raccoon",
            hp: 9,
            armor: [EnemyBuild.a(.stability, 5)],
            narrative: EnemyBuild.n(
                "A raccoon pounces from the darkness. \"My gang scared off the bats that were living here. You're next!\"",
                "The raccoon scampers off. What other dangers lurk in this cave?",
                "A raccoon that was temporarily living in a cave."
            )
        ),
        
        EnemyBuild.e(
            "cave_raccoon_squad_leader",
            "Raccoon Squad Leader",
            hp: 10,
            armor: [EnemyBuild.a(.stability, 5)],
            narrative: EnemyBuild.n(
                "\"You think you're tougher than us! Prepare to meet your doom!\" the raccoon leader chirps.",
                "Well, now the bats can live in their natural habitiat. So many things have been going wrong in the world.",
                "A very tough raccoon. It used its strength to become the leader of a raccoon crew."
            )
        ),
        
        EnemyBuild.e(
            "cave_deep_cave_troll",
            "Deep Cave Troll",
            hp: 15,
            armor: [EnemyBuild.a(.stability, 10)],
            narrative: EnemyBuild.n(
                "A massive troll appears before you. How did you not hear this coming?",
                "That fight took all your strength. How could anything live in this cave with that monster in here?",
                "A frightening troll with thick skin and tremendous strength."
            )
        ),
        
        EnemyBuild.e(
            "cave_raccoon_miner",
            "Raccoon Miner",
            hp: 7,
            armor: [EnemyBuild.a(.stability, 6)],
            narrative: EnemyBuild.n(
                "Another raccoon! This fellow has a pickaxe. He is mining rubies deep in the cave.",
                "Well, you see the reason why this cave is so precious to everyone. You journey further to find the gemstones.",
                "This raccoon uses its dexterous hands to mine precious stones."
            )
        ),
        
        EnemyBuild.e(
            "cave_id_living_ruby",
            "Living Ruby",
            hp: 6,
            armor: [EnemyBuild.a(.stability, 10)],
            narrative: EnemyBuild.n(
                "This creature appears to be formed from solid gemstones! It glows in the darkness with living light.",
                "The living ruby runs deeper into the back of the cave.",
                "The joints of this creature are carefully formed to allow movement dispite the unflexible material."
            )
        ),
        
        EnemyBuild.e(
            "cave_id_living_emerald",
            "Living Emerald",
            hp: 6,
            armor: [EnemyBuild.a(.stability, 10)],
            narrative: EnemyBuild.n(
                "A green, humanoid figure approaches you. It swings its razor sharp arm at your head!",
                "After defeating this emerald, you start to wonder how these creatures came to be.",
                "A beautiful, living gemstone. This emerald seemed to be crafted over a great period of time."
            )
        ),
        
        EnemyBuild.e(
            "cave_id_bear_cub",
            "Bear Cub",
            hp: 4,
            armor: [EnemyBuild.a(.stability, 2)],
            narrative: EnemyBuild.n(
                "\"Oh, how cute!\" you think to yourself. \"A cute little bear cub.\"",
                "The bear cries out into the cave. He seems scared.",
                "A brown, bear cub. It was very small, and almost helpless."
            )
        ),
        
        EnemyBuild.e(
            "cave_id",
            "Pair of Bear Cubs",
            hp: 4,
            armor: [EnemyBuild.a(.stability, 2)],
            narrative: EnemyBuild.n(
                "Another bear cub comes out from the darkness to join his brother. How many bears are here?",
                "Both bears run back. You see a large, shadowy figure appearing.",
                "A pair of bear cubs. They are twin brothers."
            )
        ),
        
        EnemyBuild.e(
            "id",
            "Mama Bear",
            hp: 20,
            armor: [EnemyBuild.a(.stability, 8)],
            narrative: EnemyBuild.n(
                "\"I should have known better!\" you think to yourself. But, it's too late. You have to deal with mama bear now.",
                "You manage to slip away and run out of the cave. \"Finally, sunlight!\" you say aloud.",
                "A menacing mama bear. She lives in the deepest parts of the cave, and her power is unchecked."
            )
        )
        



    ]
}

