import { realpath } from 'node:fs/promises'
import type { RepositoryIdentity } from '../domain.ts'
import type { CommandRunner } from './command-runner.ts'

const gitTimeoutMs = 5_000

export interface RepositoryResolver {
  resolvePrimary(cwd: string, signal?: AbortSignal): Promise<RepositoryIdentity>
}

export class GitRepositoryResolver implements RepositoryResolver {
  private readonly runner: CommandRunner
  private readonly canonicalize: (path: string) => Promise<string>

  constructor(
    runner: CommandRunner,
    canonicalize: (path: string) => Promise<string> = realpath,
  ) {
    this.runner = runner
    this.canonicalize = canonicalize
  }

  async resolvePrimary(
    cwd: string,
    signal?: AbortSignal,
  ): Promise<RepositoryIdentity> {
    const identity = await this.runner.run(
      'git',
      [
        'rev-parse',
        '--path-format=absolute',
        '--show-toplevel',
        '--git-common-dir',
      ],
      { cwd, signal, timeout: gitTimeoutMs },
    )
    assertGitSuccess(identity.code, identity.stderr)

    const [currentWorktreePath, commonDirPath] = parseIdentity(identity.stdout)

    const worktrees = await this.runner.run(
      'git',
      ['worktree', 'list', '--porcelain', '-z'],
      { cwd, signal, timeout: gitTimeoutMs },
    )
    assertGitSuccess(worktrees.code, worktrees.stderr)

    const primaryWorktreePath = parsePrimaryWorktree(worktrees.stdout)

    const [currentWorktree, commonDir, primaryWorktree] = await Promise.all([
      this.canonicalize(currentWorktreePath),
      this.canonicalize(commonDirPath),
      this.canonicalize(primaryWorktreePath),
    ]).catch((error: unknown) => {
      throw new RepositoryResolutionError(
        `Could not canonicalize repository paths: ${errorMessage(error)}`,
      )
    })

    if (currentWorktree !== primaryWorktree) {
      throw new PrimaryWorktreeRequiredError(currentWorktree, primaryWorktree)
    }

    return { commonDir, primaryWorktree }
  }
}

type GitResult = { code: number; stderr: string }

function assertGitSuccess(code: GitResult['code'], stderr: string): void {
  if (code === 0) return
  const detail = stderr.trim()
  throw new RepositoryResolutionError(
    detail.length > 0
      ? `Git repository discovery failed: ${detail}`
      : 'Git repository discovery failed',
  )
}

export function parseIdentity(stdout: string): [string, string] {
  const lines = stdout.endsWith('\n')
    ? stdout.slice(0, -1).split('\n')
    : stdout.split('\n')
  if (lines.length !== 2 || lines.some((line) => line.length === 0)) {
    throw new RepositoryResolutionError(
      'Git returned an unsupported repository identity response',
    )
  }
  return [lines[0] as string, lines[1] as string]
}

export function parsePrimaryWorktree(stdout: string): string {
  const firstRecord = stdout.split('\0\0').find((record) => record.length > 0)
  const worktreeField = firstRecord
    ?.split('\0')
    .find((field) => field.startsWith('worktree '))
  const path = worktreeField?.slice('worktree '.length)
  if (!path) {
    throw new RepositoryResolutionError(
      'Git returned no primary worktree in its structured worktree list',
    )
  }
  return path
}

function errorMessage(error: unknown): string {
  return error instanceof Error ? error.message : String(error)
}

export class RepositoryResolutionError extends Error {
  constructor(message: string) {
    super(message)
    this.name = 'RepositoryResolutionError'
  }
}

export class PrimaryWorktreeRequiredError extends RepositoryResolutionError {
  constructor(currentWorktree: string, primaryWorktree: string) {
    super(
      `Agent creation must start in the primary worktree (${primaryWorktree}); current worktree is ${currentWorktree}`,
    )
    this.name = 'PrimaryWorktreeRequiredError'
  }
}
