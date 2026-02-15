//
//  Enemies_Field.swift
//  FitnessAdventure
//

import Foundation

struct EnemiesField {
    static let all: [RPGEnemy] = [
        EnemyBuild.e(
            "field_vicious_rat",
            "Vicious Rat",
            hp: 5,
            narrative: EnemyBuild.n(
                "A rat lunges out at you! For some reason it keeps chasing you even though you run away.",
                "The rat scurries away going back to its rats nest.",
                "A little rat that enjoyed chasing you."
            )
        ),

        EnemyBuild.e(
            "field_coiled_serpent",
            "Coiled Serpent",
            hp: 6,
            narrative: EnemyBuild.n(
                "Lying in wait, basking on a rock a serpent appears! It hisses menacingly.",
                "Luckily, the serpent slithers away. You think you saw a rattler at the end of its tail.",
                "A snake that was about five feet long. It was most likely venomous."
            )
        ),

        EnemyBuild.e(
            "field_angry_goose",
            "Angry Goose",
            hp: 6,
            armor: [EnemyBuild.a(.stability, 2)],
            narrative: EnemyBuild.n(
                "Uh-oh, it's an angry goose! This may be the most dangerous enemy you'll face.",
                "Oh, I guess it was a mama goose protecting her gooselings. You should have been more careful.",
                "A protective mother goose. Not all nursery rhymes are about bad guys."
            )
        ),

        EnemyBuild.e(
            "field_goblin_stonemason",
            "Goblin Stonemason",
            hp: 6,
            armor: [EnemyBuild.a(.stability, 4)],
            narrative: EnemyBuild.n(
                "A goblin with a brick trowel in its hand is building a large, stone structure in the middle of the road. He turns to face you and snarls.",
                "What kind of project was he making? Knowing goblins, it can't have been for anything good.",
                "A skilled crafstgoblin with a penchant for stonework."
            )
        ),

        EnemyBuild.e(
            "field_goblin_architect",
            "Goblin Architect",
            hp: 7,
            armor: [EnemyBuild.a(.stability, 5)],
            narrative: EnemyBuild.n(
                "The planner for the building comes by to see why progress has stalled. He sees you, adventurer, and decides to fight.",
                "You defeated the mason and the architecct. What other trouble awaits you?",
                "An intelligent goblin with a degree in architecture."
            )
        ),

        EnemyBuild.e(
            "field_goblin_interior_decorator",
            "Goblin Interior Decorator",
            hp: 8,
            armor: [EnemyBuild.a(.stability, 5)],
            narrative: EnemyBuild.n(
                "A goblin holding rolls of fabric and color samples comes round the building and sees you. He swats at you with a roll of cloth.",
                "This goblin turns tail and runs away. Why is noone stopping this project?",
                "Interior design is something you wouldn't think goblins would excel at, but this one can work wonders with limited materials."
            )
        ),

        EnemyBuild.e(
            "field_goblin_project_manager",
            "Goblin Project Manager",
            hp: 8,
            armor: [EnemyBuild.a(.stability, 6)],
            narrative: EnemyBuild.n(
                "It's the boss of the project! He has a clipboard full of blueprints and a mischievous grin.",
                "\"You may have defeated me, but I'm sending our biggest worker to stop you!\" the project manager exclaims.",
                "It's truly remarkable how sophisticated goblin organization becomes when left unchecked."
            )
        ),

        EnemyBuild.e(
            "field_ogre_grunt",
            "Ogre Grunt",
            hp: 8,
            armor: [EnemyBuild.a(.stability, 10)],
            narrative: EnemyBuild.n(
                "\"You stop project. Ogre alsmot finished. Ogre smash you and finish project!\" The ogre hurls a boulder towards you.",
                "The ogre lets out a load bellow. You hear the ground begin to rumble.",
                "This ogre was upset about getting stopped midway through his project. Honestly, relatable."
            )
        ),

        EnemyBuild.e(
            "field_goblin_horde",
            "Goblin Horde",
            hp: 9,
            armor: [EnemyBuild.a(.stability, 6)],
            narrative: EnemyBuild.n(
                "A hugh gathering of goblins approaches you. \"This was going to be our headquarters to take over your kingdom! Prepare to be crushed!\"",
                "The goblins are routed, and the run off into the distance. Looks like the day is saved!",
                "Wow, we should have been keeping track of this goblin stronghold! What other problems have cropped up?"
            )
        )
    ]
}

