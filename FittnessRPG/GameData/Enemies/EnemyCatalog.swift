//
//  EnemyCatalog.swift
//  FittnessRPG
//
//  Single source of truth for RPGEnemy definitions used by quests.
//  (Now split by region to keep content manageable.)
//

import Foundation

struct EnemyCatalog {
    static let field: [RPGEnemy] = EnemiesField.all
    static let cave: [RPGEnemy] = EnemiesCave.all
    static let seaside: [RPGEnemy] = EnemiesSeaside.all
}

