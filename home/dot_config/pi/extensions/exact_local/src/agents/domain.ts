export type AgentResourceRef =
  | {
      kind: 'pi-session'
      path: string
      ownership: 'owned'
    }
  | {
      kind: 'worktree'
      path: string
      branch: string
      ownership: 'owned'
    }
  | {
      kind: 'local-branch'
      name: string
      ownership: 'owned'
    }
  | {
      kind: 'remote-branch'
      remote: string
      name: string
      ownership: 'owned' | 'associated'
    }
  | {
      kind: 'pull-request'
      nameWithOwner: string
      number: number
      headRefName: string
      ownership: 'owned' | 'associated'
    }
  | {
      kind: 'kitty-tab'
      agentId: string
      ownership: 'owned'
      volatile: true
    }
  | {
      kind: 'kitty-restore-definition'
      path: string
      ownership: 'owned'
    }

export type RepositoryIdentity = {
  commonDir: string
  primaryWorktree: string
  githubNameWithOwner?: string
}

export type ManagedAgentRecordV1 = {
  schemaVersion: 1
  id: string
  revision: number
  name: string
  parentId: string | null
  repository: RepositoryIdentity
  resources: AgentResourceRef[]
  lifecycle: 'provisioning' | 'active' | 'deleting' | 'error'
  createdAt: string
  updatedAt: string
}

const agentIdPattern =
  /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/

export function isManagedAgentRecordV1(
  value: unknown,
): value is ManagedAgentRecordV1 {
  if (!isObjectWithKeys(value, recordKeys)) return false
  return (
    value.schemaVersion === 1 &&
    isAgentId(value.id) &&
    isNonnegativeInteger(value.revision) &&
    isNonemptyString(value.name) &&
    (value.parentId === null || isAgentId(value.parentId)) &&
    isRepositoryIdentity(value.repository) &&
    Array.isArray(value.resources) &&
    value.resources.every(isAgentResourceRef) &&
    isLifecycle(value.lifecycle) &&
    isNonemptyString(value.createdAt) &&
    isNonemptyString(value.updatedAt)
  )
}

const recordKeys = [
  'schemaVersion',
  'id',
  'revision',
  'name',
  'parentId',
  'repository',
  'resources',
  'lifecycle',
  'createdAt',
  'updatedAt',
] as const

function isRepositoryIdentity(value: unknown): value is RepositoryIdentity {
  if (
    !isObjectWithKeys(
      value,
      ['commonDir', 'primaryWorktree'],
      ['githubNameWithOwner'],
    )
  ) {
    return false
  }
  return (
    isNonemptyString(value.commonDir) &&
    isNonemptyString(value.primaryWorktree) &&
    (value.githubNameWithOwner === undefined ||
      isNonemptyString(value.githubNameWithOwner))
  )
}

function isAgentResourceRef(value: unknown): value is AgentResourceRef {
  if (!isPlainObject(value) || !isNonemptyString(value.kind)) return false

  switch (value.kind) {
    case 'pi-session':
      return (
        isObjectWithKeys(value, ['kind', 'path', 'ownership']) &&
        isNonemptyString(value.path) &&
        value.ownership === 'owned'
      )
    case 'worktree':
      return (
        isObjectWithKeys(value, ['kind', 'path', 'branch', 'ownership']) &&
        isNonemptyString(value.path) &&
        isNonemptyString(value.branch) &&
        value.ownership === 'owned'
      )
    case 'local-branch':
      return (
        isObjectWithKeys(value, ['kind', 'name', 'ownership']) &&
        isNonemptyString(value.name) &&
        value.ownership === 'owned'
      )
    case 'remote-branch':
      return (
        isObjectWithKeys(value, ['kind', 'remote', 'name', 'ownership']) &&
        isNonemptyString(value.remote) &&
        isNonemptyString(value.name) &&
        isOwnership(value.ownership)
      )
    case 'pull-request':
      return (
        isObjectWithKeys(value, [
          'kind',
          'nameWithOwner',
          'number',
          'headRefName',
          'ownership',
        ]) &&
        isNonemptyString(value.nameWithOwner) &&
        typeof value.number === 'number' &&
        Number.isInteger(value.number) &&
        value.number >= 1 &&
        isNonemptyString(value.headRefName) &&
        isOwnership(value.ownership)
      )
    case 'kitty-tab':
      return (
        isObjectWithKeys(value, ['kind', 'agentId', 'ownership', 'volatile']) &&
        isAgentId(value.agentId) &&
        value.ownership === 'owned' &&
        value.volatile === true
      )
    case 'kitty-restore-definition':
      return (
        isObjectWithKeys(value, ['kind', 'path', 'ownership']) &&
        isNonemptyString(value.path) &&
        value.ownership === 'owned'
      )
    default:
      return false
  }
}

function isPlainObject(value: unknown): value is Record<string, unknown> {
  return typeof value === 'object' && value !== null && !Array.isArray(value)
}

function isObjectWithKeys<
  const Required extends readonly string[],
  const Optional extends readonly string[] = [],
>(
  value: unknown,
  required: Required,
  optional: Optional = [] as unknown as Optional,
): value is Record<Required[number] | Optional[number], unknown> {
  if (!isPlainObject(value)) return false
  const allowed = new Set<string>([...required, ...optional])
  return (
    required.every((key) => Object.hasOwn(value, key)) &&
    Object.keys(value).every((key) => allowed.has(key))
  )
}

function isAgentId(value: unknown): value is string {
  return typeof value === 'string' && agentIdPattern.test(value)
}

function isNonemptyString(value: unknown): value is string {
  return typeof value === 'string' && value.length > 0
}

function isNonnegativeInteger(value: unknown): value is number {
  return typeof value === 'number' && Number.isInteger(value) && value >= 0
}

function isOwnership(value: unknown): value is 'owned' | 'associated' {
  return value === 'owned' || value === 'associated'
}

function isLifecycle(
  value: unknown,
): value is ManagedAgentRecordV1['lifecycle'] {
  return (
    value === 'provisioning' ||
    value === 'active' ||
    value === 'deleting' ||
    value === 'error'
  )
}

export type CreateProvisioningRecordInput = {
  id: string
  name: string
  repository: RepositoryIdentity
  now: string
}

export function createProvisioningRecord(
  input: CreateProvisioningRecordInput,
): ManagedAgentRecordV1 {
  const name = input.name.trim()
  if (name.length === 0) throw new InvalidAgentNameError()

  return {
    schemaVersion: 1,
    id: input.id,
    revision: 0,
    name,
    parentId: null,
    repository: { ...input.repository },
    resources: [],
    lifecycle: 'provisioning',
    createdAt: input.now,
    updatedAt: input.now,
  }
}

export class InvalidAgentNameError extends Error {
  constructor() {
    super('Agent name must not be empty')
    this.name = 'InvalidAgentNameError'
  }
}
