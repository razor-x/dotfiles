import { randomUUID } from 'node:crypto'
import {
  chmod,
  lstat,
  mkdir,
  open,
  readFile,
  rename,
  rm,
  type FileHandle,
} from 'node:fs/promises'
import { isAbsolute, join, resolve } from 'node:path'
import { type ManagedAgentRecordV1, isManagedAgentRecordV1 } from './domain.ts'

const directoryMode = 0o700
const fileMode = 0o600
const agentIdPattern =
  /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/

export interface AgentStore {
  create(record: ManagedAgentRecordV1): Promise<string>
  read(id: string): Promise<ManagedAgentRecordV1>
}

export class FileAgentStore implements AgentStore {
  readonly stateRoot: string
  readonly agentsDirectory: string

  constructor(stateRoot: string) {
    this.stateRoot = resolve(stateRoot)
    this.agentsDirectory = join(this.stateRoot, 'agents')
  }

  pathFor(id: string): string {
    assertAgentId(id)
    return join(this.agentsDirectory, `${id}.json`)
  }

  async create(record: ManagedAgentRecordV1): Promise<string> {
    assertAgentRecord(record)
    await this.ensureDirectories()

    const destination = this.pathFor(record.id)
    if (await pathExists(destination)) {
      throw new AgentAlreadyExistsError(record.id)
    }

    const temporary = join(
      this.agentsDirectory,
      `.${record.id}.${randomUUID()}.tmp`,
    )
    let handle: FileHandle | undefined

    try {
      handle = await open(temporary, 'wx', fileMode)
      await handle.writeFile(`${JSON.stringify(record, null, 2)}\n`, 'utf8')
      await handle.sync()
      await handle.close()
      handle = undefined

      if (await pathExists(destination)) {
        throw new AgentAlreadyExistsError(record.id)
      }

      await rename(temporary, destination)
      return destination
    } finally {
      await handle?.close().catch(() => undefined)
      await rm(temporary, { force: true }).catch(() => undefined)
    }
  }

  async read(id: string): Promise<ManagedAgentRecordV1> {
    const path = this.pathFor(id)
    let text: string
    try {
      text = await readFile(path, 'utf8')
    } catch (error) {
      if (errorCode(error) === 'ENOENT') throw new AgentNotFoundError(id)
      throw error
    }

    let value: unknown
    try {
      value = JSON.parse(text)
    } catch {
      throw new InvalidAgentRecordError(path)
    }

    if (!isManagedAgentRecordV1(value) || value.id !== id) {
      throw new InvalidAgentRecordError(path)
    }
    assertCanonicalRecordPaths(value, path)
    return value
  }

  private async ensureDirectories(): Promise<void> {
    await mkdir(this.stateRoot, { recursive: true, mode: directoryMode })
    await chmod(this.stateRoot, directoryMode)
    await mkdir(this.agentsDirectory, {
      recursive: true,
      mode: directoryMode,
    })
    await chmod(this.agentsDirectory, directoryMode)
  }
}

function assertAgentRecord(record: ManagedAgentRecordV1): void {
  if (!isManagedAgentRecordV1(record)) {
    throw new InvalidAgentRecordError('<new record>')
  }
  assertCanonicalRecordPaths(record, '<new record>')
}

function assertCanonicalRecordPaths(
  record: ManagedAgentRecordV1,
  recordPath: string,
): void {
  const paths = [
    record.repository.commonDir,
    record.repository.primaryWorktree,
    ...record.resources.flatMap((resource) => {
      switch (resource.kind) {
        case 'pi-session':
        case 'worktree':
        case 'kitty-restore-definition':
          return [resource.path]
        default:
          return []
      }
    }),
  ]
  if (paths.some((path) => !isAbsolute(path))) {
    throw new InvalidAgentRecordError(recordPath)
  }
}

function assertAgentId(id: string): void {
  if (!agentIdPattern.test(id)) throw new InvalidAgentIdError(id)
}

async function pathExists(path: string): Promise<boolean> {
  try {
    await lstat(path)
    return true
  } catch (error) {
    if (errorCode(error) === 'ENOENT') return false
    throw error
  }
}

function errorCode(error: unknown): string | undefined {
  return (error as NodeJS.ErrnoException | undefined)?.code
}

export class AgentAlreadyExistsError extends Error {
  constructor(id: string) {
    super(`Agent ${id} already exists`)
    this.name = 'AgentAlreadyExistsError'
  }
}

export class AgentNotFoundError extends Error {
  constructor(id: string) {
    super(`Agent ${id} was not found`)
    this.name = 'AgentNotFoundError'
  }
}

export class InvalidAgentIdError extends Error {
  constructor(id: string) {
    super(`Invalid agent ID: ${id}`)
    this.name = 'InvalidAgentIdError'
  }
}

export class InvalidAgentRecordError extends Error {
  constructor(path: string) {
    super(`Invalid managed-agent record: ${path}`)
    this.name = 'InvalidAgentRecordError'
  }
}
