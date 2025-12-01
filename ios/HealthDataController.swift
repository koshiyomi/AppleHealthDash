import Foundation
import HealthKit

@MainActor
final class HealthDataController: ObservableObject {
    @Published private(set) var metrics: [String: String] = [:]

    private let healthStore = HKHealthStore()

    private var readTypes: Set<HKSampleType> {
        var types = Set<HKSampleType>()
        if let steps = HKObjectType.quantityType(forIdentifier: .stepCount) {
            types.insert(steps)
        }
        if let resting = HKObjectType.quantityType(forIdentifier: .restingHeartRate) {
            types.insert(resting)
        }
        if let sleep = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) {
            types.insert(sleep)
        }
        return types
    }

    func requestAuthorization() async throws {
        try await healthStore.requestAuthorization(toShare: [], read: readTypes)
    }

    func loadLatestMetrics() async {
        var results: [String: String] = [:]

        if let stepsType = HKObjectType.quantityType(forIdentifier: .stepCount) {
            if let steps = await mostRecentQuantitySample(for: stepsType, unit: .count()) {
                results["steps"] = String(Int(steps))
            }
        }

        if let restingType = HKObjectType.quantityType(forIdentifier: .restingHeartRate) {
            let bpmUnit = HKUnit.count().unitDivided(by: .minute())
            if let hr = await mostRecentQuantitySample(for: restingType, unit: bpmUnit) {
                results["heart_rate_resting"] = String(format: "%.0f bpm", hr)
            }
        }

        if let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) {
            if let minutes = await mostRecentSleepMinutes(for: sleepType) {
                results["sleep_duration_minutes"] = String(Int(minutes))
            }
        }

        await MainActor.run {
            metrics = results
        }
    }

    func sendMetrics(token: String) async throws {
        guard !metrics.isEmpty else {
            throw NSError(domain: "HealthBridge", code: 1, userInfo: [NSLocalizedDescriptionKey: "No metrics loaded"])
        }

        let url = URL(string: "https://YOUR_API_BASE_URL/health-metrics")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: metrics, options: [])

        let (_, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw NSError(domain: "HealthBridge", code: 2, userInfo: [NSLocalizedDescriptionKey: "Server rejected request"])
        }
    }

    private func mostRecentQuantitySample(for type: HKQuantityType, unit: HKUnit) async -> Double? {
        let start = Calendar.current.date(byAdding: .day, value: -7, to: Date())
        let predicate = HKQuery.predicateForSamples(withStart: start, end: Date())
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        let descriptor = HKSampleQueryDescriptor(predicate: predicate, limit: 1, sortDescriptors: [sort])

        do {
            let samples = try await descriptor.result(for: healthStore)
            guard let quantitySample = samples.first as? HKQuantitySample else { return nil }
            return quantitySample.quantity.doubleValue(for: unit)
        } catch {
            return nil
        }
    }

    private func mostRecentSleepMinutes(for type: HKCategoryType) async -> Double? {
        let start = Calendar.current.date(byAdding: .day, value: -7, to: Date())
        let predicate = HKQuery.predicateForSamples(withStart: start, end: Date())
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        let descriptor = HKSampleQueryDescriptor(predicate: predicate, limit: 1, sortDescriptors: [sort])

        do {
            let samples = try await descriptor.result(for: healthStore)
            guard let sample = samples.first as? HKCategorySample else { return nil }
            let minutes = sample.endDate.timeIntervalSince(sample.startDate) / 60.0
            return minutes
        } catch {
            return nil
        }
    }
}
