import Foundation

extension AsyncStream {
    func collect(until predicate: (Element) -> Bool) async -> [Element] {
        var results: [Element] = []
        for await element in self {
            results.append(element)
            if predicate(element) { break }
        }
        return results
    }
}
