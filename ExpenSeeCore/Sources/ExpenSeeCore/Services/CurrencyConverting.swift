//
//  CurrencyConverting.swift
//  ExpenSeeCore
//
//  Created by Harvy Angelo Tan on 8/20/26.
//


//
//  CurrencyConversion.swift
//  ExpenSeeCore
//
//  NEW FILE.
//
//  Short answer to "is there a native Swift way to convert currency": no.
//  Foundation's `Measurement`/`Dimension` types handle fixed-ratio unit
//  conversion (meters <-> feet, etc.), but currency isn't fixed-ratio —
//  rates move — so there's nothing built in. This has to come from a live
//  rate source over the network, cached locally so budget math can run
//  offline without blocking on a request.
//
//  Design: `CurrencyConverting` is what BudgetEngine actually depends on,
//  and it's synchronous + cache-only on purpose — you don't want a network
//  call happening in the middle of computing "how much can I still spend
//  today." `ExchangeRateFetching` is the thing that goes and gets fresh
//  rates; call `refreshRates()` somewhere low-stakes (app launch, a
//  background refresh task, pull-to-refresh on the budgets screen).
//

import Foundation
import SwiftData

/// What BudgetEngine actually uses: a synchronous, cache-only lookup.
/// Never makes a network call.
public protocol CurrencyConverting {
    /// Multiplier to turn 1 unit of `from` into `to`. Nil if no cached rate
    /// exists yet for that pair.
    func cachedRate(from: String, to: String) -> Decimal?

    /// Fetches fresh rates and updates the cache. Not called by BudgetEngine —
    /// call this yourself on whatever cadence makes sense for the app.
    func refreshRates() async throws
}

/// Fetches rates from a remote service. Swap in whichever provider you
/// like behind this protocol.
public protocol ExchangeRateFetching {
    /// 1 unit of `base` expressed in every other currency the provider
    /// supports, e.g. `["PHP": 56.12, "EUR": 0.92, ...]`.
    func fetchRates(base: String) async throws -> [String: Decimal]
}

/// Local cache of exchange rates. Add `ExchangeRate.self` to your
/// ModelContainerFactory's schema array.
@Model
public final class ExchangeRate {
    public var id: UUID
    public var baseCurrencyCode: String = "USD"
    public var quoteCurrencyCode: String = "USD"
    public var rate: Decimal = 1
    public var updatedAt: Date = Date.now

    public init(id: UUID = UUID(), base: String, quote: String, rate: Decimal, updatedAt: Date = .now) {
        self.id = id
        self.baseCurrencyCode = base
        self.quoteCurrencyCode = quote
        self.rate = rate
        self.updatedAt = updatedAt
    }
}

/// Default `CurrencyConverting`, backed by the SwiftData cache above.
@MainActor
public final class SwiftDataCurrencyConverter: CurrencyConverting {
    private let context: ModelContext
    private let fetcher: ExchangeRateFetching

    public init(context: ModelContext, fetcher: ExchangeRateFetching) {
        self.context = context
        self.fetcher = fetcher
    }

    public func cachedRate(from: String, to: String) -> Decimal? {
        if from == to { return 1 }
        let descriptor = FetchDescriptor<ExchangeRate>(
            predicate: #Predicate { $0.baseCurrencyCode == from && $0.quoteCurrencyCode == to }
        )
        return (try? context.fetch(descriptor))?.first?.rate
    }

    /// Refreshes rates for every currency actually in use across accounts
    /// and spending limits — not just one hardcoded base — so any pair the
    /// app needs is covered.
    public func refreshRates() async throws {
        let accountCurrencies = ((try? context.fetch(FetchDescriptor<Account>())) ?? []).map(\.currencyCode)
        let limitCurrencies = ((try? context.fetch(FetchDescriptor<SpendingLimit>())) ?? []).map(\.currencyCode)
        let bases = Set(accountCurrencies + limitCurrencies)

        for base in bases {
            let rates = try await fetcher.fetchRates(base: base)
            for (quote, rate) in rates {
                upsert(base: base, quote: quote, rate: rate)
            }
        }
        try context.save()
    }

    private func upsert(base: String, quote: String, rate: Decimal) {
        let descriptor = FetchDescriptor<ExchangeRate>(
            predicate: #Predicate { $0.baseCurrencyCode == base && $0.quoteCurrencyCode == quote }
        )
        if let existing = try? context.fetch(descriptor).first {
            existing.rate = rate
            existing.updatedAt = .now
        } else {
            context.insert(ExchangeRate(base: base, quote: quote, rate: rate))
        }
    }
}

/// Example `ExchangeRateFetching` using frankfurter.app — free, ECB-sourced,
/// no API key required. This is here so the app has something to run
/// against out of the box; swap it for whatever provider you prefer. Free
/// FX APIs change hosts/terms occasionally, so double-check
/// https://www.frankfurter.app/docs/ still matches this before shipping.
public struct FrankfurterRateFetcher: ExchangeRateFetching {
    public init() {}

    public func fetchRates(base: String) async throws -> [String: Decimal] {
        guard let url = URL(string: "https://api.frankfurter.app/latest?from=\(base)") else {
            throw URLError(.badURL)
        }
        let (data, _) = try await URLSession.shared.data(from: url)
        let decoded = try JSONDecoder().decode(FrankfurterResponse.self, from: data)
        return decoded.rates
    }

    private struct FrankfurterResponse: Decodable {
        let base: String
        let rates: [String: Decimal]
    }
}
