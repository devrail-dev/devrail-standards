---
title: "Compliance Badge"
linkTitle: "Badge"
weight: 40
description: "Add a DevRail compliance badge to your project README."
---

Show that your project follows DevRail standards by adding a compliance badge to your README.

## Custom Badge (Hosted)

```markdown
[![DevRail compliant](https://devrail.dev/images/badge.svg)](https://devrail.dev)
```

**Preview:**

[![DevRail compliant](/images/badge.svg)](https://devrail.dev)

## Shields.io Badge (Alternative)

If you prefer shields.io hosted badges:

```markdown
[![DevRail](https://img.shields.io/badge/DevRail-compliant-0969da)](https://devrail.dev)
```

## Where to Place It

Add the badge near the top of your `README.md`, alongside other project badges (CI status, license, version):

```markdown
# My Project

[![CI](https://github.com/OWNER/REPO/actions/workflows/lint.yml/badge.svg)](...)
[![DevRail compliant](https://devrail.dev/images/badge.svg)](https://devrail.dev)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
```
