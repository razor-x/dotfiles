import { mkdtemp, rm } from 'node:fs/promises'
import { createServer } from 'node:net'
import { join } from 'node:path'
import { expect, it } from 'vitest'
import { requestCapture } from '@/capture-ui.ts'

it('requests fresh PNG bytes and rejects capture errors', async () => {
  const directory = await mkdtemp('/tmp/pi-capture-test-')
  const endpoint = join(directory, 'capture.sock')
  const image = Buffer.from('89504e470d0a1a0a', 'hex')
  let response = image
  const server = createServer((socket) => {
    socket.once('data', (request) => {
      expect(request.toString()).toBe('capture\n')
      socket.end(response)
    })
  })
  try {
    await new Promise<void>((resolve) => server.listen(endpoint, resolve))
    expect(await requestCapture(endpoint)).toEqual(image)
    response = Buffer.from('ERROR: Target window disappeared')
    await expect(requestCapture(endpoint)).rejects.toThrow(
      'Target window disappeared',
    )
    const aborted = AbortSignal.abort()
    await expect(requestCapture(endpoint, aborted)).rejects.toThrow()
  } finally {
    await new Promise<void>((resolve, reject) =>
      server.close((error) => (error ? reject(error) : resolve())),
    )
    await rm(directory, { recursive: true, force: true })
  }
  await expect(requestCapture(endpoint)).rejects.toThrow()
})
