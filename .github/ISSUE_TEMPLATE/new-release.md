---
name: New release
about: Checklist for releasing a new version
title: Release x.x.x
labels: ''
assignees: ''

---

- [ ] Tidy up CHANGELOG (simplify and group entries)
- [ ] Bump [major, minor or patch version](https://semver.org/) in `VERSION` and `CHANGELOG`
- [ ] Create new GitHub release with CHANGELOG entries
- [ ] Deploy to docker
- [ ] Docker pull and update on production
- [ ] Monitor docker logs to verify clean restart
- [ ] Verify that https://xronos.ch is up
- [ ] Write news post about release (optional for patch releases)
