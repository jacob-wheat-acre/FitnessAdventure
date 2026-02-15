//
//  Enemies_Seaside.swift
//  FitnessAdventure
//

import Foundation

struct EnemiesSeaside {
    static let all: [RPGEnemy] = [
        EnemyBuild.e(
            "hungry_seagull",
            "Hungry Seagull",
            hp: 10,
            armor: [EnemyBuild.a(.stability, 2)],
            narrative: EnemyBuild.n(
                "It’s a seagull! You have been eating food and it wants to take it. Try as you might, it keeps diving at you.",
                "Phew! That's the last time you'll be waving food around openly at the beach. You think you saw something red in the seagull's mouth.",
                "This seagull spent its time looking for scraps of food along the beach. It ate whatever it could find."
            )
        ),

        EnemyBuild.e(
            "stray_dog",
            "Stray Dog",
            hp: 12,
            armor: [EnemyBuild.a(.stability, 2)],
            narrative: EnemyBuild.n(
                "Oh, how sad! Where is this dog's owner? The dog is growling at you as if it's suspicious of you.",
                "You hate to hurt a dog, but it kept chasing you down the beach. The poor dog put its tail between its legs and ran back to the woods.",
                "A dog that ran after you on the beach. I guess it thought that was a game."
            )
        ),
        
        EnemyBuild.e(
            "sneaky_fox",
            "Sneaky Fox",
            hp: 8,
            armor: [EnemyBuild.a(.stability, 8)],
            narrative: EnemyBuild.n(
                "You stumble upon a red fox! Wow, his fur is so beautiful.",
                "The fox laughed at you, grabbed a small crab from the sandy beach, and went back to its den.",
                "A majestic fox. It would be wonderful to have a fox as a pet. Maybe."
            )
        ),
        
        EnemyBuild.e(
            "giant_crab",
            "Giant Crab",
            hp: 17,
            armor: [EnemyBuild.a(.stability, 16)],
            narrative: EnemyBuild.n(
                "This is no ordinary crab! The crab towers over you and glares into your soul. It snaps its claws at you.",
                "What could have led to crabs of this size coming to be? Something is not right here.",
                "A truly giant crab. You wish you could have eaten it."
            )
        ),
        
        EnemyBuild.e(
            "craboid_soldier",
            "Craboid Soldier",
            hp: 20,
            armor: [EnemyBuild.a(.stability, 15)],
            narrative: EnemyBuild.n(
                "Walking out of the depths of the sea comes a man-crab, a craboid. It looks fierce.",
                "After battling the craboid, it motions for you to come to a vessel on the shore. You climb aboard the ship.",
                "This is a crab-human hybrid. These creatures possess qualities of both crabs and humans."
            )
        ),
        
        EnemyBuild.e(
            "craboid_ship_captain",
            "Craboid Ship Captain",
            hp: 25,
            armor: [EnemyBuild.a(.stability, 15)],
            narrative: EnemyBuild.n(
                "\"Welcome aboard. If you defeat me in combat, I will respect you,\" the captain says. He is another craboid.",
                "The captain admits defeat, and he takes you out on his vessel. You are now on the sea, and you approach a glowing light in the depths of the waters.",
                "The captain of this ship was well trained in combat. He dodged your blows by moving back and forth."
            )
        ),
        
        EnemyBuild.e(
            "craboid_diver",
            "Craboid Diver",
            hp: 25,
            armor: [EnemyBuild.a(.stability, 20)],
            narrative: EnemyBuild.n(
                "A diver equips you with a diving apparatus. He wants to see a demonstration of your strength before you take the plunge.",
                "You jump overboard with the craboid diver. You swim deep down into the sea towards a glowing city. You pass into a huge bubble of air and stand on solid ground.",
                "This craboid diver showed you the underwater craboid city."
            )
        ),
        
        EnemyBuild.e(
            "craboid_city_guard",
            "Craboid City Guard",
            hp: 15,
            armor: [EnemyBuild.a(.stability, 25)],
            narrative: EnemyBuild.n(
                "A craboid greets you as you approach the gate. He points a spear at you and grunts.",
                "You pass through the gate and enter the underwater city. There are craboid people all around you.",
                "A diligent guard of an underwater city."
            )
        ),
        
        EnemyBuild.e(
            "craboid_commoner",
            "Craboid Commoner",
            hp: 10,
            armor: [EnemyBuild.a(.stability, 15)],
            narrative: EnemyBuild.n(
                "As you walk down the street, a craboid steps out from the crow to challenge you!",
                "You defeat the commoner. As you move along, you hear a shout from behind you.",
                "A brave craboid commoner."
            )
        ),
        
        EnemyBuild.e(
            "craboid_crowd",
            "Craboid Crowd",
            hp: 25,
            armor: [EnemyBuild.a(.stability, 15)],
            narrative: EnemyBuild.n(
                "An outlaw craboid pirate is crying towards you. \"Follow me! These craboids will eat you alive if you continue!\" The crowd surges toward you\"",
                "You and the craboid pirate escape. He takes you to his vessel pulled by seahorses.",
                "You were close to becoming dinner for these craboids."
            )
        ),
        
        EnemyBuild.e(
            "giant_squid",
            "Giant Squid",
            hp: 40,
            armor: [EnemyBuild.a(.stability, 10)],
            narrative: EnemyBuild.n(
                "As you approach the surface, your vessel is grabbed by a giant squid!",
                "You manage to escape the tentacled grasp of the giant squid.",
                "You were almost eaten by craboids, but you thought you'd like to have eaten this squid."
            )
        ),
        
        EnemyBuild.e(
            "row_boat",
            "Row Boat",
            hp: 50,
            armor: [EnemyBuild.a(.stability, 0)],
            narrative: EnemyBuild.n(
                "Back on the surface, the pirate takes you to an empty row boat. Use your force to return to home.",
                "After great efforts you manage to row ashore. You are greeted by a storekeeper on land who saw you leave with the craboids.",
                "You wish you could have gotten dropped off on shore, but you can understand why the craboids fear us."
            )
        ),
        
        EnemyBuild.e(
            "store_keeper",
            "Store Keeper",
            hp: 0,
            armor: [EnemyBuild.a(.stability, 30)],
            narrative: EnemyBuild.n(
                "The store keeper asks you for help breaking down some shelves. Use your precision to do this quickly.",
                "After all the adventure, you decide to leave this seashore and make your way inland. The storekeeper thanks you for your help.",
                "At least you were able to make yourself useful to this old store keeper."
            )
        )
    ]
}

