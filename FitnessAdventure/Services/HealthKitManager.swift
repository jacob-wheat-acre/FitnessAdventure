import HealthKit
import Foundation

final class HealthKitManager {
    static let shared = HealthKitManager()
    private let healthStore = HKHealthStore()

    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        guard let energyType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned),
              let walkingDistance = HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning),
              let cyclingDistance = HKQuantityType.quantityType(forIdentifier: .distanceCycling),
              let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate) else {
            completion(false)
            return
        }

        let typesToRead: Set<HKObjectType> = [
            HKObjectType.workoutType(),
            energyType,
            walkingDistance,
            cyclingDistance,
            heartRateType
        ]

        healthStore.requestAuthorization(toShare: [], read: typesToRead) { success, _ in
            completion(success)
        }
    }

    // Existing method (unchanged)
    func fetchRecentWorkouts(limit: Int = 20, completion: @escaping ([HKWorkout]) -> Void) {
        let workoutType = HKWorkoutType.workoutType()
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)

        let query = HKSampleQuery(
            sampleType: workoutType,
            predicate: nil,
            limit: limit,
            sortDescriptors: [sort]
        ) { _, samples, _ in
            let workouts = samples as? [HKWorkout] ?? []
            completion(workouts)
        }

        healthStore.execute(query)
    }

    /// NEW: Fetch workouts constrained to a rolling time window (e.g., last 72 hours).
    func fetchWorkouts(inLastHours hours: Int = 72, limit: Int = 200, completion: @escaping ([HKWorkout]) -> Void) {
        let workoutType = HKWorkoutType.workoutType()
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)

        let now = Date()
        let start = Calendar.current.date(byAdding: .hour, value: -max(1, hours), to: now) ?? now.addingTimeInterval(-Double(hours) * 3600)

        // Include workouts whose endDate is within the window.
        let predicate = HKQuery.predicateForSamples(withStart: start, end: now, options: .strictEndDate)

        let query = HKSampleQuery(
            sampleType: workoutType,
            predicate: predicate,
            limit: limit,
            sortDescriptors: [sort]
        ) { _, samples, _ in
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

        let predicate = HKQuery.predicateForObjects(from: workout)

        let query = HKStatisticsQuery(
            quantityType: type,
            quantitySamplePredicate: predicate,
            options: .cumulativeSum
        ) { _, stats, _ in
            let calories = stats?.sumQuantity()?.doubleValue(for: .kilocalorie()) ?? 0
            completion(calories)
        }

        healthStore.execute(query)
    }

    func fetchDistance(for workout: HKWorkout, completion: @escaping (Double) -> Void) {
        let type: HKQuantityType?
        switch workout.workoutActivityType {
        case .running, .walking, .hiking:
            type = HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning)
        case .cycling:
            type = HKQuantityType.quantityType(forIdentifier: .distanceCycling)
        default:
            type = nil
        }

        guard let distanceType = type else {
            completion(0)
            return
        }

        let predicate = HKQuery.predicateForObjects(from: workout)

        let query = HKStatisticsQuery(
            quantityType: distanceType,
            quantitySamplePredicate: predicate,
            options: .cumulativeSum
        ) { _, stats, _ in
            let meters = stats?.sumQuantity()?.doubleValue(for: .meter()) ?? 0
            completion(meters / 1609.34) // miles
        }

        healthStore.execute(query)
    }

    /// Returns average heart rate in beats per minute (BPM) over the workout.
    /// If heart rate data isn't available/authorized, this returns nil.
    func fetchAverageHeartRate(for workout: HKWorkout, completion: @escaping (Double?) -> Void) {
        guard let hrType = HKQuantityType.quantityType(forIdentifier: .heartRate) else {
            completion(nil)
            return
        }

        let predicate = HKQuery.predicateForObjects(from: workout)

        let query = HKStatisticsQuery(
            quantityType: hrType,
            quantitySamplePredicate: predicate,
            options: .discreteAverage
        ) { _, stats, _ in
            let bpmUnit = HKUnit.count().unitDivided(by: HKUnit.minute())
            let avg = stats?.averageQuantity()?.doubleValue(for: bpmUnit)
            completion(avg)
        }

        healthStore.execute(query)
    }
}
