Here's how to implement a binary search in Go:

```go
func binarySearch(arr []int, target int) int {
    low, high := 0, len(arr)-1

    for low <= high {
        mid := low + (high-low)/2

        if arr[mid] == target {
            return mid
        } else if arr[mid] < target {
            low = mid + 1
        } else {
            high = mid - 1
        }
    }

    return -1 // not found
}
```

### How it works

1. Start with the full array range
2. Compare the middle element with the target
3. If equal, return the index
4. If less, search the right half
5. If greater, search the left half

Time complexity: **O(log n)**. Space complexity: **O(1)**.
