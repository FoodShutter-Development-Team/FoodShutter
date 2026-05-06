//
//  MealStatusObserver.swift
//  FoodShutter
//
//  Observes meals.status to drive the two-phase analysis pipeline.
//  Primary path: Supabase Realtime (using postgresChange async sequence)
//  Fallback path: REST polling (3s interval, 60s total timeout)
//

import Foundation
import Supabase

enum MealStatusEvent {
    case dishesReady
    case complete
    case failed(String?)
    case timeout
}

final class MealStatusObserver {
    let mealId: UUID

    init(mealId: UUID) {
        self.mealId = mealId
    }

    /// Returns an AsyncStream that sequentially emits dishesReady → complete / failed / timeout
    func stream() -> AsyncStream<MealStatusEvent> {
        AsyncStream { [mealId] continuation in
            let realtimeTask = Task { await Self.subscribeRealtime(mealId: mealId, continuation: continuation) }
            let pollTask     = Task { await Self.poll(mealId: mealId, continuation: continuation) }

            continuation.onTermination = { _ in
                realtimeTask.cancel()
                pollTask.cancel()
            }
        }
    }

    // MARK: - Realtime

    private static func subscribeRealtime(
        mealId: UUID,
        continuation: AsyncStream<MealStatusEvent>.Continuation
    ) async {
        let channel = supabase.channel("meal-status-\(mealId.uuidString)")
        let seen = _SeenFlags()

        let subscription = channel.onPostgresChange(
            UpdateAction.self,
            schema: "public",
            table:  "meals",
            filter: "id=eq.\(mealId.uuidString)"
        ) { update in
            let status = update.record["status"]?.stringValue ?? ""
            switch status {
            case "dishes_ready":
                if !seen.seenDishesReady {
                    seen.seenDishesReady = true
                    continuation.yield(.dishesReady)
                }
            case "complete":
                continuation.yield(.complete)
                continuation.finish()
            case "failed":
                let error = update.record["pipeline_error"]?.stringValue
                continuation.yield(.failed(error))
                continuation.finish()
            default:
                break
            }
        }

        try? await channel.subscribeWithError()
        defer { subscription.cancel(); Task { await channel.unsubscribe() } }

        while !Task.isCancelled {
            try? await Task.sleep(nanoseconds: 500_000_000)
        }
    }

    // MARK: - Helpers

    private final class _SeenFlags: @unchecked Sendable {
        var seenDishesReady = false
    }

    // MARK: - Polling Fallback

    private static func poll(
        mealId: UUID,
        continuation: AsyncStream<MealStatusEvent>.Continuation
    ) async {
        let deadline   = Date().addingTimeInterval(60)
        var seenDishesReady = false
        var seenComplete    = false

        while !Task.isCancelled && Date() < deadline {
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            guard !Task.isCancelled else { return }

            guard let row = try? await supabase
                .from("meals")
                .select("status, pipeline_error")
                .eq("id", value: mealId)
                .single()
                .execute()
                .value as MealStatusRow
            else { continue }

            switch row.status {
            case "dishes_ready":
                if !seenDishesReady {
                    seenDishesReady = true
                    continuation.yield(.dishesReady)
                }
            case "complete":
                if !seenComplete {
                    seenComplete = true
                    continuation.yield(.complete)
                    continuation.finish()
                    return
                }
            case "failed":
                continuation.yield(.failed(row.pipelineError))
                continuation.finish()
                return
            default:
                break
            }
        }

        guard !Task.isCancelled else { return }
        continuation.yield(.timeout)
        continuation.finish()
    }
}
