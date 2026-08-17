export function stub<T>(implementation: Partial<T>): T {
  return implementation as T
}
