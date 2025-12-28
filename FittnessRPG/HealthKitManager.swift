import HealthKit
import Foundation

class HealthKitManager {
    static let shared = HealthKitManager()
    private let healthStore = HKHealthStore()

    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        guard let energyType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned),
              let walkingDistance = HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning),
              let cyclingDistance = HKQuantityType.quantityType(forIdentifier: .distanceCycling) else {
            completion(false)
            return
        }

        let types: Set<HKObjectType> = [HKObjectType.workoutType(), energyType, walkingDistance, cyclingDistance]

        healthStore.requestAuthorization(toShare: [], read: types) { success, _ in
            completion(success)
        }
    }

    func fetchRecentWorkouts(limit: Int = 20, completion: @escaping ([HKWorkout]) -> Void) {
        let workoutType = HKWorkoutType.workoutType()
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        let query = HKSampleQuery(sampleType: workoutType, predicate: nil, limit: limit, sortDescriptors: [sort]) { _, samples, _ in
            let workouts = samples as? [HKWorkout] ?? []
            completion(workouts)
        }
        healthStore.execute(query)
    }

    func fetchCalories(for workout: HKWorkout, completion: @escaping (Double) -> Void) {
        guard let type = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) else {
            completion(0)
            return
        }

        let query = HKStatisticsQuery(quantityType: type,
                                      quantitySamplePredicate: HKQuery.predicateForObjects(from: workout),
                                      options: .cumulativeSum) { _, stats, _ in
            let calories = stats?.sumQuantity()?.doubleValue(for: .kilocalorie()) ?? 0
            completion(calories)
        }
        healthStore.execute(query)
    }

    func fetchDistance(for workout: HKWorkout, completion: @escaping (Double) -> Void) {
        let type: HKQuantityType?
        switch workout.workoutActivityType {
        case .running, .walking: type = HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning)
        case .cycling: type = HKQuantityType.quantityType(forIdentifier: .distanceCycling)
        default: type = nil
        }
        guard let distanceType = type else { completion(0); return }

        let query = HKStatisticsQuery(quantityType: distanceType,
                                      quantitySamplePredicate: HKQuery.predicateForObjects(from: workout),
                                      options: .cumulativeSum) { _, stats, _ in
            let meters = stats?.sumQuantity()?.doubleValue(for: .meter()) ?? 0
            completion(meters / 1609.34) // miles
        }
        healthStore.execute(query)
    }
}
