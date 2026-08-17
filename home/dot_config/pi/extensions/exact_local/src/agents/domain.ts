import Schema from 'typebox/schema'
import { Type, type Static } from 'typebox'

const owned = Type.Literal('owned')
const ownedOrAssociated = Type.Union([
  Type.Literal('owned'),
  Type.Literal('associated'),
])

export const agentResourceRefSchema = Type.Union([
  Type.Object(
    {
      kind: Type.Literal('pi-session'),
      path: Type.String({ minLength: 1 }),
      ownership: owned,
    },
    { additionalProperties: false },
  ),
  Type.Object(
    {
      kind: Type.Literal('worktree'),
      path: Type.String({ minLength: 1 }),
      branch: Type.String({ minLength: 1 }),
      ownership: owned,
    },
    { additionalProperties: false },
  ),
  Type.Object(
    {
      kind: Type.Literal('local-branch'),
      name: Type.String({ minLength: 1 }),
      ownership: owned,
    },
    { additionalProperties: false },
  ),
  Type.Object(
    {
      kind: Type.Literal('remote-branch'),
      remote: Type.String({ minLength: 1 }),
      name: Type.String({ minLength: 1 }),
      ownership: ownedOrAssociated,
    },
    { additionalProperties: false },
  ),
  Type.Object(
    {
      kind: Type.Literal('pull-request'),
      nameWithOwner: Type.String({ minLength: 1 }),
      number: Type.Integer({ minimum: 1 }),
      headRefName: Type.String({ minLength: 1 }),
      ownership: ownedOrAssociated,
    },
    { additionalProperties: false },
  ),
  Type.Object(
    {
      kind: Type.Literal('kitty-tab'),
      agentId: Type.String({ minLength: 1 }),
      ownership: owned,
      volatile: Type.Literal(true),
    },
    { additionalProperties: false },
  ),
  Type.Object(
    {
      kind: Type.Literal('kitty-restore-definition'),
      path: Type.String({ minLength: 1 }),
      ownership: owned,
    },
    { additionalProperties: false },
  ),
])

export type AgentResourceRef = Static<typeof agentResourceRefSchema>

export const managedAgentRecordV1Schema = Type.Object(
  {
    schemaVersion: Type.Literal(1),
    id: Type.String({
      pattern: '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
    }),
    revision: Type.Integer({ minimum: 0 }),
    name: Type.String({ minLength: 1 }),
    parentId: Type.Union([Type.String({ minLength: 1 }), Type.Null()]),
    repository: Type.Object(
      {
        commonDir: Type.String({ minLength: 1 }),
        primaryWorktree: Type.String({ minLength: 1 }),
        githubNameWithOwner: Type.Optional(Type.String({ minLength: 1 })),
      },
      { additionalProperties: false },
    ),
    resources: Type.Array(agentResourceRefSchema),
    lifecycle: Type.Union([
      Type.Literal('provisioning'),
      Type.Literal('active'),
      Type.Literal('deleting'),
      Type.Literal('error'),
    ]),
    createdAt: Type.String({ minLength: 1 }),
    updatedAt: Type.String({ minLength: 1 }),
  },
  { additionalProperties: false },
)

export type ManagedAgentRecordV1 = Static<typeof managedAgentRecordV1Schema>
export type RepositoryIdentity = ManagedAgentRecordV1['repository']

const managedAgentRecordV1Validator = Schema.Compile(managedAgentRecordV1Schema)

export function isManagedAgentRecordV1(
  value: unknown,
): value is ManagedAgentRecordV1 {
  return managedAgentRecordV1Validator.Check(value)
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
