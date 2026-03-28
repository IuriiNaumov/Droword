import Foundation

func levenshteinDistance(_ s: String, _ t: String) -> Int {
    let sArr = Array(s)
    let tArr = Array(t)
    let m = sArr.count
    let n = tArr.count

    if m == 0 { return n }
    if n == 0 { return m }

    var prev = Array(0...n)
    var curr = [Int](repeating: 0, count: n + 1)

    for i in 1...m {
        curr[0] = i
        for j in 1...n {
            let cost = sArr[i - 1] == tArr[j - 1] ? 0 : 1
            curr[j] = min(
                prev[j] + 1,
                curr[j - 1] + 1,
                prev[j - 1] + cost
            )
        }
        prev = curr
    }
    return prev[n]
}
