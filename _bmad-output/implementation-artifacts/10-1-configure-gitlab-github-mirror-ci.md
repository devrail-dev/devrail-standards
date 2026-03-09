# Story 10.1: Configure GitLab-to-GitHub Mirror CI

Status: done

## Story

As a maintainer,
I want the GitLab CI pipeline to automatically mirror pushes to main to the GitHub remote,
so that the GitHub mirror stays in sync without manual intervention.

## Acceptance Criteria

1. The `mirror-to-github` job in `.gitlab-ci.yml` runs successfully on pushes to main
2. A `$GITHUB_MIRROR_SSH_KEY` CI/CD variable is configured in the GitLab project settings
3. The GitHub mirror (`devrail-dev/devrail-standards`) is automatically updated within minutes of a push to GitLab main
4. The mirror job uses a deploy key (not a personal SSH key) for security

## Tasks / Subtasks

- [ ] Task 1: Generate a dedicated SSH deploy key for GitHub mirroring (AC: 4)
  - [ ] 1.1 Generate a new SSH key pair specifically for the mirror job
  - [ ] 1.2 Add the public key as a deploy key on the `devrail-dev/devrail-standards` GitHub repo (with write access)
  - [ ] 1.3 Add the private key as `$GITHUB_MIRROR_SSH_KEY` CI/CD variable in the GitLab project (masked, protected)

- [ ] Task 2: Verify the mirror job runs (AC: 1, 2, 3)
  - [ ] 2.1 Push a trivial commit to main and verify the `mirror-to-github` job triggers
  - [ ] 2.2 Confirm the GitHub mirror reflects the latest GitLab main commit
  - [ ] 2.3 Verify the job completes in under 30 seconds

## Dev Notes

- The `.gitlab-ci.yml` already has the `mirror-to-github` job configured — it just needs the CI variable
- The job uses `alpine:latest` with `git` and `openssh-client` installed at runtime
- The job runs `git push --force` to the GitHub remote — this is safe since GitLab is the source of truth
- The job is gated on `$CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH && $GITHUB_MIRROR_SSH_KEY`
- Current SSH key (`~/.ssh/matthew@mellor.earth`) should NOT be used — create a purpose-built deploy key

### References

- [Source: .gitlab-ci.yml] — mirror-to-github job definition
- [Source: repos.md] — repo map and remote configuration

## Dev Agent Record

### Agent Model Used

### Debug Log References

### Completion Notes List

### File List
