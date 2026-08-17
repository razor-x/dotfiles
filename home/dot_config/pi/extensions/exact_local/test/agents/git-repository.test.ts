import type { ExecOptions, ExecResult } from '@earendil-works/pi-coding-agent'
import { describe, expect, it } from 'vitest'
import type { CommandRunner } from '@/agents/adapters/command-runner.ts'
import {
  GitRepositoryResolver,
  PrimaryWorktreeRequiredError,
  RepositoryResolutionError,
} from '@/agents/adapters/git-repository.ts'

describe('GitRepositoryResolver', () => {
  it('uses structured read-only Git commands and returns canonical identity', async () => {
    const runner = new ScriptedRunner([
      success('/repo/example\n/repo/example/.git\n'),
      success('worktree /repo/example\0HEAD abc\0branch refs/heads/main\0\0'),
    ])
    const resolver = new GitRepositoryResolver(
      runner,
      async (path) => `/canonical${path}`,
    )

    await expect(resolver.resolvePrimary('/repo/example')).resolves.toEqual({
      commonDir: '/canonical/repo/example/.git',
      primaryWorktree: '/canonical/repo/example',
    })
    expect(runner.calls).toEqual([
      {
        command: 'git',
        args: [
          'rev-parse',
          '--path-format=absolute',
          '--show-toplevel',
          '--git-common-dir',
        ],
        options: {
          cwd: '/repo/example',
          signal: undefined,
          timeout: 5_000,
        },
      },
      {
        command: 'git',
        args: ['worktree', 'list', '--porcelain', '-z'],
        options: {
          cwd: '/repo/example',
          signal: undefined,
          timeout: 5_000,
        },
      },
    ])
  })

  it('refuses creation outside the primary worktree', async () => {
    const runner = new ScriptedRunner([
      success('/repo/example/.worktrees/topic\n/repo/example/.git\n'),
      success(
        'worktree /repo/example\0HEAD abc\0branch refs/heads/main\0\0' +
          'worktree /repo/example/.worktrees/topic\0HEAD def\0branch refs/heads/topic\0\0',
      ),
    ])
    const resolver = new GitRepositoryResolver(runner, async (path) => path)

    await expect(
      resolver.resolvePrimary('/repo/example/.worktrees/topic'),
    ).rejects.toBeInstanceOf(PrimaryWorktreeRequiredError)
  })

  it('reports Git discovery failures without attempting another command', async () => {
    const runner = new ScriptedRunner([
      {
        stdout: '',
        stderr: 'fatal: not a git repository',
        code: 128,
        killed: false,
      },
    ])
    const resolver = new GitRepositoryResolver(runner, async (path) => path)

    await expect(resolver.resolvePrimary('/outside')).rejects.toEqual(
      new RepositoryResolutionError(
        'Git repository discovery failed: fatal: not a git repository',
      ),
    )
    expect(runner.calls).toHaveLength(1)
  })
})

type RunnerCall = {
  command: string
  args: readonly string[]
  options?: ExecOptions
}

class ScriptedRunner implements CommandRunner {
  readonly calls: RunnerCall[] = []
  private readonly results: ExecResult[]

  constructor(results: ExecResult[]) {
    this.results = results
  }

  async run(
    command: string,
    args: readonly string[],
    options?: ExecOptions,
  ): Promise<ExecResult> {
    this.calls.push({ command, args, options })
    const result = this.results.shift()
    if (!result) throw new Error(`Unexpected command: ${command}`)
    return result
  }
}

function success(stdout: string): ExecResult {
  return { stdout, stderr: '', code: 0, killed: false }
}
