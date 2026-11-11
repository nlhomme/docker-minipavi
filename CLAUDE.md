# docker-minipavi

Docker images for MiniPavi (gateway, emulator, WebMedia, welcome/EXTcall services, Asterisk). The repo holds no MiniPavi code: each Dockerfile downloads a release of `ludosevilla/minipavi` at build time.

The owner is a DevOps engineer, not a programmer. Documentation, comments and log messages are in French.

## Rule: the documentation must ALWAYS be up to date

Any change to the repo that alters what a reader would do or expect must update the documentation **in the same change**, never later. That covers `README.md`, every article in `Documentation/`, `.env.example`, and the comments in the Dockerfiles, scripts and templates.

- Before finishing a change, ask: does any sentence, table, command or example in the documentation now say something false or incomplete? If yes, fix it now.
- A new file, image, variable, port, profile, script or log message is not done until it is documented.
- When something is removed or renamed, remove or rename every mention of it; search the whole repo for the old name.
- Commands and examples in the documentation must be ones that work as written. If one could not be tried, say so in the text.
- If the documentation and the code disagree, that is a bug: fix it even if it is unrelated to the task at hand, or report it.

### Before every commit or push

The owner also edits files by hand, so the changes about to be committed are not only yours. When asked to commit or push, apply this rule to **everything** that is going in, whoever made it:

1. Look at the full set of changes first (`git status`, `git diff`, staged and unstaged, plus untracked files), not only at what you changed in this session.
2. For each change you did not make yourself, check it against the documentation, `docker-compose.yml` and `.env.example` exactly as you would for your own: is anything now false, missing or renamed?
3. If something needs updating, update it and include it in the same commit. Tell the owner what you added and why, so they can object.
4. If a manual change looks unintended or contradicts the documentation and you cannot tell which side is right, do not guess: ask before committing.
5. Run `./test.sh` before committing when the changes touch a Dockerfile, a script, a template or `docker-compose.yml`.

Never commit a state where the documentation is known to be out of date.

## Rule: every way of running the images must stay equivalent

There are two ways to run the images, and they must always deliver the same thing (same features, same variables, same ports, same defaults, same behaviour):

- the **Dockerfiles**, run one by one (`docker build` / `docker run`, or one Coolify resource each);
- **`docker-compose.yml`**, which runs them together.

So whenever one side changes, update the other in the same change:

- A Dockerfile is added, renamed or removed: add, rename or remove its service in `docker-compose.yml`.
- An environment variable or build argument is added, renamed or removed (in a `*.template`, a `start-*` script or a Dockerfile `ARG`): do the same in `docker-compose.yml` and `.env.example`.
- A port, a default value, a required/optional status or a network need changes: change it on both sides.
- A change made first in `docker-compose.yml` (a new variable, port, default) must be carried back to the Dockerfile, scripts and templates. Compose must never offer something the standalone images cannot do, and the reverse.

The documentation is part of the same contract. In the same change, update:

- the article of the image in `Documentation/` (`10-` to `14-`), which documents the standalone way;
- `Documentation/02-liaisons.md` if a variable links two images;
- `Documentation/30-docker-compose.md` and `Documentation/31-hebergement-coolify.md` if ports, profiles or variables change;
- `Documentation/21-depannage.md` if a log message is added or reworded.

## Check

Run `./test.sh` after any such change (`./test.sh latest asterisk` when the Asterisk image or its templates are touched). Its first step fails if a Dockerfile has no service in `docker-compose.yml`, or if a variable of the images is missing from `docker-compose.yml` or from `Documentation/`. That static check does not compare ports or default values: check those by hand.

## Conventions

- One folder per image, named after its `docker-compose.yml` service (`minipavi`, `emulminitel`, `webmedia`, `accueil-extcall`, `asterisk`), holding its `Dockerfile` and everything only that image uses. Files shared by several images go in `commun/`. The repo root keeps only what concerns the whole repo.
- The build context is always the repo root (`docker build -f <image>/Dockerfile .`), because of `commun/`.
- Service articles (`Documentation/10-` to `14-`) describe plain Docker only. Anything specific to a host goes in its own article (`Documentation/3x-`).
- `MINIPAVI_VERSION` defaults to the latest upstream release on purpose; the warning about it in `README.md` and `Documentation/01-version-minipavi.md` must stay.
- Never commit secrets: values come from environment variables; `.env` is git-ignored.
