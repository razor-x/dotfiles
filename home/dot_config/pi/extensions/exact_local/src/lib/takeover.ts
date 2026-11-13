import { randomUUID } from 'node:crypto'
import { existsSync, rmSync } from 'node:fs'
import { lstat, mkdir, readdir } from 'node:fs/promises'
import { createConnection, createServer, type Socket } from 'node:net'
import { isAbsolute, join } from 'node:path'

export const takeoverDirectory = `/tmp/pi-takeover-${process.getuid?.()}`

interface SessionDescription {
  sessionFile: string
  name: string
}

export interface TakeoverOwner extends SessionDescription {
  socketPath: string
  token: string
  pid: number
}

export type TakeoverService = Awaited<ReturnType<typeof startTakeoverService>>

async function checkDirectory(directory: string): Promise<void> {
  const stat = await lstat(directory)
  if (
    !stat.isDirectory() ||
    stat.uid !== process.getuid?.() ||
    (stat.mode & 0o077) !== 0
  ) {
    throw new Error(
      `Takeover directory must be private and owned by you: ${directory}`,
    )
  }
}

export async function startTakeoverService(directory = takeoverDirectory) {
  await mkdir(directory, { recursive: true, mode: 0o700 })
  await checkDirectory(directory)

  const socketPath = join(directory, `${randomUUID()}.sock`)
  let binding:
    | {
        describe: () => SessionDescription | undefined
        shutdown: () => void
        token: string
      }
    | undefined
  let requested = false
  const describe = () => {
    try {
      return binding?.describe()
    } catch {
      return undefined
    }
  }
  const sockets = new Set<Socket>()
  const server = createServer((socket) => {
    sockets.add(socket)
    socket.unref()
    socket.on('error', () => socket.destroy())
    socket.on('close', () => sockets.delete(socket))
    socket.setTimeout(2000, () => socket.destroy())

    const current = binding
    const owner = describe()
    if (!current || !owner || !existsSync(owner.sessionFile) || requested) {
      socket.end('idle\n')
      return
    }
    socket.write(
      `${JSON.stringify({ ...owner, token: current.token, pid: process.pid })}\n`,
    )

    let request = ''
    socket.setEncoding('utf8')
    socket.on('data', (chunk: string) => {
      request += chunk
      if (request.length > 128) {
        socket.destroy()
        return
      }
      if (!request.includes('\n')) {
        return
      }
      if (
        request !== `takeover ${current.token}\n` ||
        binding !== current ||
        describe()?.sessionFile !== owner.sessionFile ||
        requested
      ) {
        socket.end('refused\n')
        return
      }

      requested = true
      socket.setTimeout(0)
      socket.write('accepted\n', () => {
        try {
          current.shutdown()
        } catch {
          // A failed shutdown must never look like a completed handoff.
          requested = false
          socket.end('failed\n')
        }
      })
    })
  })

  await new Promise<void>((resolve, reject) => {
    server.once('error', reject)
    server.listen(socketPath, () => {
      server.off('error', reject)
      resolve()
    })
  })
  server.unref()

  const unlink = () => rmSync(socketPath, { force: true })
  process.once('exit', unlink)

  return {
    socketPath,
    bind(describe: () => SessionDescription | undefined, shutdown: () => void) {
      binding = { describe, shutdown, token: randomUUID() }
    },
    unbind() {
      binding = undefined
    },
    async close() {
      process.off('exit', unlink)
      for (const socket of sockets) {
        socket.destroy()
      }
      await new Promise<void>((resolve) => server.close(() => resolve()))
      unlink()
    },
  }
}

function parseOwner(line: string, socketPath: string): TakeoverOwner {
  const value: unknown = JSON.parse(line)
  if (
    typeof value !== 'object' ||
    value === null ||
    !('sessionFile' in value) ||
    typeof value.sessionFile !== 'string' ||
    !isAbsolute(value.sessionFile) ||
    !('name' in value) ||
    typeof value.name !== 'string' ||
    !('token' in value) ||
    typeof value.token !== 'string' ||
    !/^[\da-f-]{36}$/.test(value.token) ||
    !('pid' in value) ||
    typeof value.pid !== 'number' ||
    !Number.isSafeInteger(value.pid) ||
    value.pid <= 0
  ) {
    throw new Error('Invalid takeover owner response')
  }
  return {
    sessionFile: value.sessionFile,
    name: value.name,
    token: value.token,
    pid: value.pid,
    socketPath,
  }
}

function contactOwner(
  socketPath: string,
  selected?: TakeoverOwner,
  timeoutMs = 1000,
): Promise<TakeoverOwner | undefined> {
  const socket = createConnection(socketPath)
  let timer: ReturnType<typeof setTimeout>
  return new Promise<TakeoverOwner | undefined>((resolve, reject) => {
    let buffer = ''
    let owner: TakeoverOwner | undefined
    let accepted = false
    timer = setTimeout(() => {
      reject(
        new Error(
          'Takeover timed out; the owner may still finish and exit later. No session was opened.',
        ),
      )
    }, timeoutMs)
    socket.setEncoding('utf8')
    socket.on('error', reject)
    socket.on('data', (chunk: string) => {
      buffer += chunk
      if (buffer.length > 16384) {
        reject(new Error('Takeover response too large'))
        return
      }
      let newline = buffer.indexOf('\n')
      while (newline !== -1) {
        const line = buffer.slice(0, newline)
        buffer = buffer.slice(newline + 1)
        try {
          if (!owner) {
            if (line === 'idle') {
              if (selected) {
                throw new Error(
                  'Owner is switching sessions, shutting down, or already handling a takeover.',
                )
              }
              resolve(undefined)
              return
            }
            owner = parseOwner(line, socketPath)
            if (!selected) {
              resolve(owner)
              return
            }
            if (
              owner.token !== selected.token ||
              owner.sessionFile !== selected.sessionFile
            ) {
              throw new Error('Session owner changed. Run /takeover again.')
            }
            socket.write(`takeover ${selected.token}\n`)
          } else if (line === 'accepted' && !accepted) {
            accepted = true
          } else {
            throw new Error(
              'Takeover refused: owner changed or another takeover is pending.',
            )
          }
        } catch (error) {
          reject(error)
          return
        }
        newline = buffer.indexOf('\n')
      }
    })
    // The owner deliberately keeps this connection open through all shutdown hooks.
    socket.on('end', () => {
      if (accepted) {
        void contactOwner(socketPath).then(
          () =>
            reject(
              new Error(
                'Owner disconnected but is still running. No session was opened.',
              ),
            ),
          (error: unknown) => {
            if (
              error instanceof Error &&
              'code' in error &&
              (error.code === 'ENOENT' || error.code === 'ECONNREFUSED')
            ) {
              resolve(owner)
            } else {
              reject(error)
            }
          },
        )
      } else {
        reject(
          new Error(
            'Owner disconnected before accepting takeover. No session was opened.',
          ),
        )
      }
    })
  }).finally(() => {
    clearTimeout(timer)
    socket.destroy()
  })
}

export async function listTakeoverOwners(
  directory = takeoverDirectory,
): Promise<TakeoverOwner[]> {
  let names: string[]
  try {
    await checkDirectory(directory)
    names = await readdir(directory)
  } catch (error) {
    if (error instanceof Error && 'code' in error && error.code === 'ENOENT') {
      return []
    }
    throw error
  }
  const owners = await Promise.all(
    names
      .filter((name) => /^[\da-f-]{36}\.sock$/.test(name))
      .map(async (name) => {
        // Crashes can leave sockets behind; an unreachable endpoint is not an owner.
        return contactOwner(join(directory, name)).catch(() => undefined)
      }),
  )
  return owners.filter((owner) => owner !== undefined)
}

export async function requestTakeover(
  owner: TakeoverOwner,
  timeoutMs = 300_000,
): Promise<void> {
  await contactOwner(owner.socketPath, owner, timeoutMs)
}
